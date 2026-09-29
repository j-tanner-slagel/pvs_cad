;;; tools/prof: profiling the evaluator on the n-level decision (dev tooling, not
;;; part of the library or of the trusted path).  Loaded by tools/prof.sh.
(defvar *cad-scratch* "/tmp/cad_scratch")
(defvar *cad-warm-secs* 15)
(defvar *cad-dprof-fns*
  '(|pvs2cl-_rcf| |pvs2cl-_nrh| |pvs2cl-_isoc| |pvs2cl-_zero_at| |pvs2cl-_chain| |pvs2cl-_scof|
    |pvs2cl-_tables| |pvs2cl-_tblof| |pvs2cl-_mktbl| |pvs2cl-_mkpairs| |pvs2cl-_schain|
    |pvs2cl-_treads_o| |pvs2cl-_tclos_o| |pvs2cl-_seps_t| |pvs2cl-_wi_rd_t| |pvs2cl-_we_rd_t|
    |pvs2cl-_sg_sec| |pvs2cl-_alg_sign2| |pvs2cl-_subs|
    |pvs2cl-_proj| |pvs2cl-_bprod| |pvs2cl-_pprod| |pvs2cl-_zipadd|
    |pvs2cl-_rd_norm| |pvs2cl-_cellsr_o| |pvs2cl-_osec| |pvs2cl-_secp_n| |pvs2cl-_chain_t|
    |pvs2cl-_ird_t| |pvs2cl-_i_rd| |pvs2cl-_mkce| |pvs2cl-_cnt_t| |pvs2cl-_svarc_o|
    |pvs2cl-_okn_o| |pvs2cl-_innern_o| |pvs2cl-_lvok_o| |pvs2cl-_okqs| |pvs2cl-_allok?|
    |pvs2cl-_nclos_o| |pvs2cl-_nbads_o| |pvs2cl-_topreads| |pvs2cl-_lvln_o| |pvs2cl-_rts|
    |pvs2cl-_allroots| |pvs2cl-_sortu| |pvs2cl-_inv_chk| |pvs2cl-_badl| |pvs2cl-_qsecl|
    |pvs2cl-_wok_t| |pvs2cl-_sint_t| |pvs2cl-_swide_t|
    |pvs2cl-_coin_t| |pvs2cl-_mcnt_t| |pvs2cl-_feff| |pvs2cl-_addnew| |pvs2cl-_dedup1|))

(defun cad-dprof-run (expr)
  (let ((t0 (get-internal-real-time)) (done nil) (val nil))
    ;; the evaluator compiles functions lazily, on first call: a short
    ;; unprofiled run of the same expression first, so that the functions
    ;; exist when the timers are installed (compiling whole theories with
    ;; pvs2cl-theory is NOT equivalent: it evaluates differently)
    (handler-case (sb-ext:with-timeout *cad-warm-secs* (evalexpr expr nil nil t))
      (sb-ext:timeout () nil))
    (sb-profile:unprofile)
    (dolist (f *cad-dprof-fns*) (when (fboundp f) (eval `(sb-profile:profile ,f))))
    (sb-profile:reset)
    (handler-case
        (sb-ext:with-timeout *cad-prof-secs*
          (setq val (evalexpr expr nil nil t)) (setq done t))
      (sb-ext:timeout () nil))
    (with-open-file (s (concatenate (quote string) *cad-scratch* "/cad_dprof.txt") :direction :output :if-exists :supersede)
      (format s "EXPR: ~a~%DONE: ~a secs: ~,1f~%VALUE: ~a~%~%" (subseq expr 0 (min 300 (length expr))) done
              (/ (- (get-internal-real-time) t0) internal-time-units-per-second)
              (when val (let ((str (expr2str val))) (subseq str 0 (min 300 (length str))))))
      (let ((*standard-output* s) (*trace-output* s)) (sb-profile:report)))
    (sb-profile:unprofile)
    done))

(defstep cad-dprof (&optional (fnum 1))
  (let ((dummy (cad-dprof-run *cad-prof-expr*)))
    (printf "cad-dprof: report written"))
  "scratch: deterministic profile of *cad-prof-expr*" "")
