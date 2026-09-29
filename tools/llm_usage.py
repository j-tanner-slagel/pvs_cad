#!/usr/bin/env python3
"""Aggregate LLM usage from Claude Code session transcripts.

Reads every *.jsonl under the Claude Code project directory for this repository
(main sessions and their subagent transcripts), sums the per-message token counts
that the API reports, and writes:

  paper/llm_usage.csv         one row per session (plus a TOTAL row)
  paper/llm_usage.tex         a LaTeX table body for the methods section
  paper/llm_usage_phases.csv  one row per phase (windows from paper/phases.csv)
  paper/llm_usage_phases.tex  the per-phase LaTeX table

Phases are time windows (UTC) listed in paper/phases.csv; every model turn is
attributed to the phase whose window contains its timestamp (an open end_utc
means "until now"). Turns outside every window are reported as "unassigned".

Usage:  tools/llm_usage.py [--project-dir DIR] [--out paper]

Columns: session id, date, wall-clock span (h), assistant turns, tool calls,
input tokens (uncached), cache-write tokens, cache-read tokens, output tokens,
thinking tokens (subset of output), models used, session title.

Nothing here is estimated: every number is a field the API returned, summed.
Wall-clock span is last timestamp minus first timestamp, so it includes idle time
between prompts; the per-phase table also reports active hours, the sum of the gaps
between consecutive turns shorter than ACTIVE_GAP_MINUTES, which excludes the periods
when the development was left alone.
"""
import argparse, csv, glob, json, os, sys
from collections import defaultdict
from datetime import datetime

# Claude Code keeps transcripts under ~/.claude/projects/<repo path with "/" as "-">
DEFAULT_PROJECT_DIR = os.path.expanduser(
    "~/.claude/projects/" + os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("/", "-"))

# A pause longer than this between two model turns is idle time, not work.
ACTIVE_GAP_MINUTES = 10

# Printable names for the models that appear in the transcripts.
SHORT_MODEL = {"claude-fable-5-1": "Fable 5.1",
               "claude-opus-5": "Opus 5",
               "claude-sonnet-5": "Sonnet 5",
               "claude-haiku-4-5-20251001": "Haiku 4.5"}


def parse_ts(ts):
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def scan(path):
    """Return a usage dict for one transcript file."""
    u = dict(turns=0, tool_calls=0, input=0, cache_write=0, cache_read=0,
             output=0, thinking=0, first=None, last=None, models=set(), title="", events=[])
    with open(path, errors="replace") as fh:
        for line in fh:
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            ts = d.get("timestamp")
            if ts:
                t = parse_ts(ts)
                u["first"] = t if u["first"] is None or t < u["first"] else u["first"]
                u["last"] = t if u["last"] is None or t > u["last"] else u["last"]
            if d.get("type") == "ai-title" and d.get("title"):
                u["title"] = d["title"]
            m = d.get("message")
            if not isinstance(m, dict):
                continue
            if d.get("type") == "assistant":
                content = m.get("content") or []
                if isinstance(content, list):
                    u["tool_calls"] += sum(1 for c in content
                                           if isinstance(c, dict) and c.get("type") == "tool_use")
            usage = m.get("usage")
            if not usage:
                continue
            u["turns"] += 1
            if m.get("model"):
                u["models"].add(m["model"])
            u["input"] += usage.get("input_tokens", 0) or 0
            u["cache_write"] += usage.get("cache_creation_input_tokens", 0) or 0
            u["cache_read"] += usage.get("cache_read_input_tokens", 0) or 0
            u["output"] += usage.get("output_tokens", 0) or 0
            th = (usage.get("output_tokens_details") or {}).get("thinking_tokens", 0) or 0
            u["thinking"] += th
            tc = 0
            if d.get("type") == "assistant" and isinstance(m.get("content"), list):
                tc = sum(1 for c in m["content"] if isinstance(c, dict) and c.get("type") == "tool_use")
            u["events"].append((parse_ts(ts) if ts else None, usage.get("input_tokens", 0) or 0,
                                usage.get("cache_creation_input_tokens", 0) or 0,
                                usage.get("cache_read_input_tokens", 0) or 0,
                                usage.get("output_tokens", 0) or 0, th, tc,
                                m.get("model") or ""))
    return u


def read_phases(path):
    phases = []
    if not os.path.exists(path):
        return phases
    with open(path) as fh:
        for r in csv.DictReader(fh):
            start = parse_ts(r["start_utc"]) if r["start_utc"] else None
            end = parse_ts(r["end_utc"]) if r["end_utc"] else None
            phases.append((r["phase"], start, end, r.get("description", "")))
    return phases


def write_phases(events, out):
    phases = read_phases(os.path.join(out, "phases.csv"))
    if not phases:
        return
    acc = {p[0]: dict(turns=0, tool_calls=0, input=0, cache_write=0, cache_read=0, output=0, thinking=0,
                      first=None, last=None, times=[], models=defaultdict(int)) for p in phases}
    acc["unassigned"] = dict(turns=0, tool_calls=0, input=0, cache_write=0, cache_read=0, output=0, thinking=0,
                             first=None, last=None, times=[], models=defaultdict(int))
    for (t, inp, cw, cr, outp, th, tc, model) in events:
        name = "unassigned"
        if t is not None:
            for (pn, start, end, _) in phases:
                if (start is None or t >= start) and (end is None or t < end):
                    name = pn
                    break
        a = acc[name]
        a["turns"] += 1; a["tool_calls"] += tc; a["input"] += inp; a["cache_write"] += cw
        a["cache_read"] += cr; a["output"] += outp; a["thinking"] += th
        if model:
            a["models"][model] += 1
        if t is not None:
            a["first"] = t if a["first"] is None or t < a["first"] else a["first"]
            a["last"] = t if a["last"] is None or t > a["last"] else a["last"]
            a["times"].append(t)
    order = [p[0] for p in phases] + ["unassigned"]
    desc = {p[0]: p[3] for p in phases}

    def fmt(n):
        return f"{n:,}".replace(",", "\\,")

    def main_model(models):
        """The model that produced most of the turns of a phase, as a short name,
        with the others appended when they are not negligible."""
        if not models:
            return ""
        ranked = sorted(models.items(), key=lambda kv: -kv[1])
        total = sum(models.values())
        parts = [SHORT_MODEL.get(m, m) for m, n in ranked if n / total >= 0.05]
        return "/".join(parts) if parts else SHORT_MODEL.get(ranked[0][0], ranked[0][0])

    def active_hours(times, gap_minutes=ACTIVE_GAP_MINUTES):
        """Sum of the intervals between consecutive turns that are shorter than
        gap_minutes; a longer interval is counted as idle time (the machine was
        left alone) and contributes nothing."""
        ts = sorted(t for t in times if t is not None)
        cap = gap_minutes * 60
        return sum(d for d in ((ts[i + 1] - ts[i]).total_seconds() for i in range(len(ts) - 1))
                   if d < cap) / 3600

    with open(os.path.join(out, "llm_usage_phases.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["phase", "model", "span_hours", "active_hours", "turns", "tool_calls", "input",
                    "cache_write", "cache_read", "output", "thinking", "description"])
        for n in order:
            a = acc[n]
            if a["turns"] == 0:
                continue
            hrs = (a["last"] - a["first"]).total_seconds() / 3600 if a["first"] else 0.0
            w.writerow([n, main_model(a["models"]), round(hrs, 2), round(active_hours(a["times"]), 2),
                        a["turns"], a["tool_calls"], a["input"], a["cache_write"], a["cache_read"],
                        a["output"], a["thinking"], desc.get(n, "")])
    with open(os.path.join(out, "llm_usage_phases.tex"), "w") as fh:
        fh.write("% generated by tools/llm_usage.py; do not edit\n")
        fh.write("\\begin{tabular}{llrrrrrrrr}\n\\toprule\n")
        fh.write("Phase & Model & Span (h) & Active (h) & Turns & Tool calls & Input & Cache write & Cache read & Output \\\\\n\\midrule\n")
        for n in order:
            a = acc[n]
            if a["turns"] == 0:
                continue
            hrs = (a["last"] - a["first"]).total_seconds() / 3600 if a["first"] else 0.0
            fh.write(f"{n} & {main_model(a['models'])} & {hrs:.1f} & {active_hours(a['times']):.1f} & {fmt(a['turns'])} & "
                     f"{fmt(a['tool_calls'])} & {fmt(a['input'])} & "
                     f"{fmt(a['cache_write'])} & {fmt(a['cache_read'])} & {fmt(a['output'])} \\\\\n")
        fh.write("\\bottomrule\n\\end{tabular}\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project-dir", default=DEFAULT_PROJECT_DIR)
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "paper"))
    args = ap.parse_args()

    files = sorted(glob.glob(os.path.join(args.project_dir, "**", "*.jsonl"), recursive=True))
    if not files:
        sys.exit(f"no transcripts under {args.project_dir}")

    # Group subagent transcripts (in <session-id>/...) with their main session.
    sessions = defaultdict(list)
    for f in files:
        rel = os.path.relpath(f, args.project_dir)
        sid = rel.split(os.sep)[0].replace(".jsonl", "")
        sessions[sid].append(f)

    events = []
    rows = []
    total = dict(turns=0, tool_calls=0, input=0, cache_write=0, cache_read=0, output=0, thinking=0, hours=0.0)
    for sid, fs in sorted(sessions.items(), key=lambda kv: min(os.path.getmtime(f) for f in kv[1])):
        agg = dict(turns=0, tool_calls=0, input=0, cache_write=0, cache_read=0, output=0, thinking=0,
                   first=None, last=None, models=set(), title="")
        for f in fs:
            u = scan(f)
            events.extend(u["events"])
            for k in ("turns", "tool_calls", "input", "cache_write", "cache_read", "output", "thinking"):
                agg[k] += u[k]
            agg["models"] |= u["models"]
            agg["title"] = agg["title"] or u["title"]
            for k in ("first", "last"):
                if u[k] is not None and (agg[k] is None or (k == "first" and u[k] < agg[k]) or (k == "last" and u[k] > agg[k])):
                    agg[k] = u[k]
        if agg["turns"] == 0:
            continue
        hours = (agg["last"] - agg["first"]).total_seconds() / 3600 if agg["first"] and agg["last"] else 0.0
        row = dict(session=sid[:8], date=agg["first"].date().isoformat() if agg["first"] else "",
                   hours=round(hours, 2), turns=agg["turns"], tool_calls=agg["tool_calls"],
                   input=agg["input"], cache_write=agg["cache_write"], cache_read=agg["cache_read"],
                   output=agg["output"], thinking=agg["thinking"],
                   models=";".join(sorted(agg["models"])), title=agg["title"], files=len(fs))
        rows.append(row)
        for k in ("turns", "tool_calls", "input", "cache_write", "cache_read", "output", "thinking"):
            total[k] += agg[k]
        total["hours"] += hours

    os.makedirs(args.out, exist_ok=True)
    cols = ["session", "date", "hours", "turns", "tool_calls", "input", "cache_write", "cache_read",
            "output", "thinking", "models", "title", "files"]
    with open(os.path.join(args.out, "llm_usage.csv"), "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader()
        for r in rows:
            w.writerow(r)
        w.writerow(dict(session="TOTAL", date="", hours=round(total["hours"], 2), turns=total["turns"],
                        tool_calls=total["tool_calls"], input=total["input"], cache_write=total["cache_write"],
                        cache_read=total["cache_read"], output=total["output"], thinking=total["thinking"],
                        models="", title="", files=len(files)))

    def fmt(n):
        return f"{n:,}".replace(",", "\\,")

    with open(os.path.join(args.out, "llm_usage.tex"), "w") as fh:
        fh.write("% generated by tools/llm_usage.py; do not edit\n")
        fh.write("\\begin{tabular}{llrrrrrrr}\n\\toprule\n")
        fh.write("Session & Date & Hours & Turns & Tool calls & Input & Cache write & Cache read & Output \\\\\n\\midrule\n")
        for r in rows:
            fh.write(f"{r['session']} & {r['date']} & {r['hours']:.1f} & {fmt(r['turns'])} & {fmt(r['tool_calls'])} & "
                     f"{fmt(r['input'])} & {fmt(r['cache_write'])} & {fmt(r['cache_read'])} & {fmt(r['output'])} \\\\\n")
        fh.write("\\midrule\n")
        fh.write(f"Total & & {total['hours']:.1f} & {fmt(total['turns'])} & {fmt(total['tool_calls'])} & "
                 f"{fmt(total['input'])} & {fmt(total['cache_write'])} & {fmt(total['cache_read'])} & {fmt(total['output'])} \\\\\n")
        fh.write("\\bottomrule\n\\end{tabular}\n")
        fh.write(f"% thinking tokens (included in output): {total['thinking']:,}\n")

    write_phases(events, args.out)

    print(f"{len(rows)} sessions, {len(files)} transcript files")
    print(f"hours {total['hours']:.1f}  turns {total['turns']}  tool_calls {total['tool_calls']}")
    print(f"input {total['input']:,}  cache_write {total['cache_write']:,}  cache_read {total['cache_read']:,}  "
          f"output {total['output']:,} (thinking {total['thinking']:,})")


if __name__ == "__main__":
    main()
