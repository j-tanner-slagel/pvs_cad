# Third-party material

pvs_cad requires PVS and NASALib, which are not included here.

- **Bath CAD example bank.** `cad/bench_pdec.pvs`, `cad/bench_n.pvs` and `cad/cad_bath.pvs`
  contain problems of the Bath CAD example bank translated into PVS: R. Bradford,
  J. H. Davenport and D. Wilson, "A repository for CAD examples", ACM Communications in Computer
  Algebra 46(3), 2012; dataset maintained by D. Wilson, University of Bath Research Data Archive,
  version 4 (2013), doi 10.15125/BATH-00069, licensed CC BY-SA 4.0. These three files are
  distributed under CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/).
- **pvs-cli.** `tools/pvs-cli.py` is adapted from `pvs-scripts/pvs-cli/pvs-cli.py` in NASALib
  (https://github.com/nasa/pvslib) and is distributed under NASALib's license.
- **PVS.** `tools/pvs-circular-deps.lisp` is derived from `src/context.lisp` of PVS
  (https://github.com/SRI-CSL/PVS), Copyright (c) SRI International, BSD 3-Clause License; the
  license text is in the file's header.
