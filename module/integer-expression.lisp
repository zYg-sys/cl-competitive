(defpackage :cp/integer-expression
  (:use :cl)
  (:export #:integer-reverse #:integer-reverse* #:palindrome-integer-p #:integer-concat))
(in-package :cp/integer-expression)

(declaim (inline integer-reverse))
(defun integer-reverse (x &optional (base 10))
  "Returns the integer displayed in reversed order of X."
  (declare ((integer 2 #.most-positive-fixnum) base))
  (declare (integer x))
  (let ((sign (signum x))
        (x (abs x))
        (res 0))
    (loop (when (zerop x)
            (return (* res sign)))
          (multiple-value-bind (quot rem) (floor x base)
            (setq res (+ (* base res) rem)
                  x quot)))))

(declaim (inline integer-reverse*))
(defun integer-reverse* (x l r &optional (base 10))
  (declare ((integer 0 #.most-positive-fixnum) l r)
           ((integer 2 #.most-positive-fixnum) base)
           (integer x))
  (assert (<= l r))
  (let ((sign (signum x))
        (x (abs x))
        (stack 0)
        (rev 0))
    (dotimes (_ l)
      (multiple-value-bind (quot rem) (floor x base)
        (setq stack (+ (* stack base) rem)
              x quot)))
    (dotimes (_ (- r l))
      (multiple-value-bind (quot rem) (floor x base)
        (setq rev (+ (* rev base) rem)
              x quot)))
    (dotimes (_ (- r l))
      (setq x (* x base)))
    (incf x rev)
    (dotimes (_ l)
      (multiple-value-bind (quot rem) (floor stack base)
        (setq x (+ (* x base) rem)
              stack quot)))
    (* x sign)))

(declaim (inline palindrome-integer-p))
(defun palindrome-integer-p (x &optional (base 10))
  "Returns true iff X is palindromically displayed."
  (declare ((integer 2 #.most-positive-fixnum) base))
  (= x (integer-reverse x base)))

(declaim (inline integer-concat))
(defun integer-concat (x y &optional (base 10))
  (declare ((integer 0 #.most-positive-fixnum) x y)
           ((integer 2 #.most-positive-fixnum) base))
  (let ((coef 1))
    (declare ((integer 0 #.most-positive-fixnum) base))
    (loop until (> coef y)
          do (setq coef (* coef base)))
    (+ (* x coef) y)))
