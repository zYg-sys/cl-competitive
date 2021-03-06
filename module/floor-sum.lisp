(defpackage :cp/floor-sum
  (:use :cl)
  (:export #:floor-sum)
  (:documentation
   "Reference:
https://github.com/atcoder/ac-library/blob/master/atcoder/math.hpp"))
(in-package :cp/floor-sum)

(defun floor-sum (n slope intercept denom)
  "Returns the sum of floor((slope * i + intercept)/denom) for i = 0, 1, ...,
N-1."
  (declare ((integer 0) slope intercept n)
           ((integer 1) denom))
  (let ((res 0))
    (declare ((integer 0) res))
    (when (>= slope denom)
      (multiple-value-bind (quot rem) (floor slope denom)
        (incf res (* (floor (* n (- n 1)) 2) quot))
        (setq slope rem)))
    (when (>= intercept denom)
      (multiple-value-bind (quot rem) (floor intercept denom)
        (incf res (* n quot))
        (setq intercept rem)))
    (let ((y (floor (+ (* slope n) intercept) denom)))
      (if (zerop y)
          res
          (let ((num (- (* denom y) intercept)))
            (incf res (* y (- n (ceiling num slope))))
            (incf res (floor-sum y denom (mod (- slope (mod num slope)) slope) slope))
            res)))))
