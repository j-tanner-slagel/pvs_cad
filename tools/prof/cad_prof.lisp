;;; tools/prof: profiling the evaluator on the n-level decision (dev tooling, not
;;; part of the library or of the trusted path).  Loaded by tools/prof.sh.
(defvar *cad-scratch* "/tmp/cad_scratch")
(unless (find-package :sb-sprof) (load *cad-sprof-fasl*))

(defvar *cad-prof-secs* 120)
(defvar *cad-prof-expr* nil)   ; if set, profile this expression instead
(defvar *cad-prof-out* (concatenate (quote string) *cad-scratch* "/cad_prof.txt"))

(defun cad-prof-run (expr)
  (let ((t0 (get-internal-real-time)) (val nil) (done nil))
    (sb-sprof:reset)
    (sb-sprof:with-profiling (:max-samples 400000 :mode :cpu :sample-interval 0.002 :report nil :threads :all)
      (handler-case
          (sb-ext:with-timeout *cad-prof-secs*
            (setq val (evalexpr expr nil nil t))
            (setq done t))
        (sb-ext:timeout () nil)))
    (with-open-file (s *cad-prof-out* :direction :output :if-exists :supersede)
      (format s "EXPR: ~a~%DONE: ~a  secs: ~,1f~%VALUE: ~a~%~%" expr done
              (/ (- (get-internal-real-time) t0) internal-time-units-per-second)
              (when val (let ((str (expr2str val))) (subseq str 0 (min 400 (length str))))))
      (sb-sprof:report :type :flat :max 80 :stream s)
      (format s "~%~%======== GRAPH ========~%")
      (sb-sprof:report :type :graph :max 40 :stream s))
    done))

(defstep cad-prof (&optional (fnum 1))
  (let ((fexpr  (extra-get-formula fnum))
        (pp     (when fexpr (cad-prefix fexpr)))
        (pre    (when pp (first pp)))
        (body   (when pp (second pp)))
        (dummy1 (setq *mpoly-atoms* (reverse (mapcar #'car pre))))
        (dummy2 (setq *cad-polys* nil))
        (phistr (when (and pre body) (cad-bf body)))
        (lists  (when phistr (loop for pr in *cad-polys* collect
                              (let ((v (evalexpr (format nil "as_list(pnorm(~a))" (car pr)) nil nil t)))
                                (when v (expr2str v))))))
        (fstr   (qe-list-str lists "null[list[mpoly]]"))
        (osstr  (format nil "(: ~{~a~^, ~} :)"
                        (loop for q in pre collect (if (cdr q) "TRUE" "FALSE"))))
        (expr   (or *cad-prof-expr*
                    (format nil "decn_o(0, ~a, ~a, LAMBDA (v: SV): bfsv(~a, v))" osstr fstr phistr)))
        (dummy3 (cad-prof-run expr)))
    (printf "cad-prof: report written"))
  "scratch: profile the n-level decision on FNUM" "")
