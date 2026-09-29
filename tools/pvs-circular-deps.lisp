;;; Derived from src/context.lisp of PVS (https://github.com/SRI-CSL/PVS):
;;; circular-file-dependencies and circular-file-dependencies*, with a visited set added.
;;;
;;; Copyright (c) 2026, SRI International's Computer Science Laboratory
;;; Redistribution and use in source and binary forms, with or without modification, are
;;; permitted provided that the following conditions are met:
;;; 1. Redistributions of source code must retain the above copyright notice, this list
;;;    of conditions and the following disclaimer.
;;; 2. Redistributions in binary form must reproduce the above copyright notice, this list
;;;    of conditions and the following disclaimer in the documentation and/or other
;;;    materials provided with the distribution.
;;; 3. Neither the name of the copyright holder nor the names of its contributors may be
;;;    used to endorse or promote products derived from this software without specific
;;;    prior written permission.
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
;;; EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;; MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
;;; THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
;;; OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;;
;;; ~/.pvs.lisp -- loaded by PVS at startup (not with pvs -q).
;;;
;;; PVS 8.1's check for circular file dependencies, run after every
;;; interactive typecheck (pvs.lisp, typecheck-theories), follows every
;;; import path without remembering what it has explored, so its cost is
;;; the number of PATHS through the import graph.  In a large layered
;;; library (this repository's cad/: about 95 million paths from a file importing the
;;; decision) it does not finish, and Emacs waits on it forever.
;;; This is the same function with a visited set, so each theory is
;;; explored once per check.  It reports the same circularities: the
;;; circularity test still runs before the visited test, on every path.
;;; Delete this file to go back to PVS's own version.

(in-package :pvs)

(defvar *cfd-visited* nil)

(defun circular-file-dependencies (filename)
  (let* ((fname (pvs-filename filename))
         (deps (assoc fname *circular-file-dependencies* :test #'equal)))
    (if deps
        (cdr deps)
        (let* ((*cfd-visited* (make-hash-table :test #'eq))
               (cdeps (circular-file-dependencies*
                       (cdr (gethash fname (current-pvs-files))))))
          (push (cons fname (car cdeps)) *circular-file-dependencies*)
          (car cdeps)))))

(defun circular-file-dependencies* (theories &optional deps circs)
  (if (null theories)
      circs
      (let* ((theory (car theories))
             (fname (dep-filename theory)))
        (unless (assoc fname *circular-file-dependencies* :test #'equal)
          (cond ((and (cdr deps)
                      (equal fname (dep-filename (car (last deps))))
                      (some #'(lambda (dep)
                                (not (equal fname (dep-filename dep))))
                            deps))
                 ;; found a circularity
                 (circular-file-dependencies* (cdr theories) deps
                                              (cons (reverse (cons theory deps))
                                                    circs)))
                ((and *cfd-visited* (gethash theory *cfd-visited*))
                 ;; explored already, on another path
                 (circular-file-dependencies* (cdr theories) deps circs))
                (t
                 (when *cfd-visited* (setf (gethash theory *cfd-visited*) t))
                 (append (circular-file-dependencies*
                          (delete-if #'(lambda (ith)
                                         (or (null ith) (from-prelude? ith)))
                            (let ((*current-context* (saved-context theory)))
                              (if (generated-by theory)
                                  (list (get-theory (generated-by theory)))
                                  (delete-if #'lib-datatype-or-theory?
                                    (mapcar #'(lambda (th) (get-theory th))
                                      (get-immediate-usings theory))))))
                          (cons theory deps))
                         (circular-file-dependencies* (cdr theories)
                                                      deps circs))))))))
