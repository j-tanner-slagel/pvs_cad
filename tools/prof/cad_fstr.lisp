;;; tools/prof: profiling the evaluator on the n-level decision (dev tooling, not
;;; part of the library or of the trusted path).  Loaded by tools/prof.sh.
(defvar *cad-scratch* "/tmp/cad_scratch")
(defstep cad-fstr (&optional (fnum 1))
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
        (dummy3 (with-open-file (s (concatenate (quote string) *cad-scratch* "/cad_fstr.out") :direction :output :if-exists :supersede)
                  (format s "F=~a~%QS=~a~%PHI=~a~%" fstr osstr phistr))))
    (printf "cad-fstr: written"))
  "scratch: write the family, prefix and matrix strings of FNUM" "")
