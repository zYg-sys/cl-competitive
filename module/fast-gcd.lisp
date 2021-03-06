;;;
;;; GCD and LCM
;;; Reference:
;;; https://lemire.me/blog/2013/12/26/fastest-way-to-compute-the-greatest-common-divisor/
;;;

(defpackage :cp/fast-gcd
  (:use :cl :cp/tzcount)
  (:export #:fast-gcd #:fast-lcm #:%fast-gcd))
(in-package :cp/fast-gcd)

(declaim (inline %fast-gcd fast-gcd fast-lcm))

(declaim (ftype (function * (values (integer 1 #.most-positive-fixnum) &optional)) %fast-gcd))
(defun %fast-gcd (u v)
  (declare ((integer 0 #.most-positive-fixnum) u v))
  (let ((shift (tzcount (logior u v))))
    (declare (optimize (safety 0)))
    (setq u (ash u (- (tzcount u))))
    (loop (setq v (ash v (- (tzcount v))))
          (when (> u v)
            (rotatef u v))
          (decf v u)
          (when (zerop v)
            (return (the (integer 1 #.most-positive-fixnum)
                         (ash u shift)))))))

(declaim (ftype (function * (values (integer 0 #.most-positive-fixnum) &optional)) fast-gcd))
(defun fast-gcd (u v)
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) u v))
  (cond ((zerop u) v)
        ((zerop v) u)
        (t (%fast-gcd u v))))

(declaim (ftype (function * (values (integer 0) &optional)) fast-lcm))
(defun fast-lcm (u v)
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) u v))
  (if (or (zerop u) (zerop v))
      0
      (multiple-value-bind (max min)
          (if (> u v)
              (values u v)
              (values v u))
        (* (truncate max (%fast-gcd u v)) min))))
