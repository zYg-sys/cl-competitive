(defpackage :cp/quad-equation
  (:use :cl)
  (:export #:solve-quad-equation))
(in-package :cp/quad-equation)

;; TODO: handling for the cases a == 0
(declaim (inline solve-quad-equation))
(defun solve-quad-equation (a b c)
  "Solves ax^2 + bx + c = 0"
  (assert (not (zerop a)))
  (let* ((a (float a 1d0))
         (b (float b 1d0))
         (c (float c 1d0))
         (d (sqrt (- (* b b) (* 4 a c)))))
    (labels ((solve2 ()
               (return-from solve-quad-equation
                 (values (/ (+ (- b) d) (* 2 a))
                         (/ (- d b) (* 2 a)))))
             (nan-p (x)
               (and (typep x 'double-float)
                    (sb-ext:float-nan-p x))))
      (handler-bind ((arithmetic-error (lambda (_) (declare (ignore _)) (solve2))))
        (let ((result1 (/ (+ (abs b) d) (* 2 a))))
          (multiple-value-bind (res1 res2)
              (if (< b 0)
                  (values result1 (/ c (* a result1)))
                  (values (- result1) (/ c (* a (- result1)))))
            (if (or (nan-p res1) (nan-p res2))
                (solve2)
                (values res1 res2))))))))
