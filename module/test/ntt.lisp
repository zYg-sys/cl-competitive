(defpackage :cp/test/ntt
  (:use :cl :fiveam :cp/ntt :cp/mod-polynomial)
  (:import-from :cp/test/base #:base-suite)
  (:import-from :cp/ntt #:%calc-generator))
(in-package :cp/test/ntt)
(in-suite base-suite)

(define-ntt +ntt-mod+)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defconstant +ntt-mod2+ 1012924417))
(define-ntt +ntt-mod2+
  :ntt ntt2
  :inverse-ntt inverse-ntt2
  :convolve convolve2)

(test ntt/hand
  (is (equalp #() (convolve #() #())))
  (is (equalp #(15) (convolve #(3) #(5))))
  (is (equalp #(998244308 17 2 998244348 1)
              (convolve #(5 998244350 1) #(998244344 998244351 1)))))

(defun make-random-polynomial (degree state modulus)
  (let ((res (make-array degree :element-type 'ntt-int :initial-element 0)))
    (dotimes (i degree res)
      (setf (aref res i) (random modulus state)))
    (let ((end (+ 1 (or (position 0 res :from-end t :test-not #'eql) -1))))
      (adjust-array res end))))

(defun generator-p (x modulus)
  (let ((marked (make-array modulus :element-type 'bit :initial-element 0)))
    (loop with value = 1
          until (= 1 (aref marked value))
          do (setf (aref marked value) 1
                   value (mod (* value x) modulus))
          finally (return
                    (cond ((/= value 1) nil)
                          ((= (- modulus 1) (count 1 marked)) t)
                          (t nil))))))

(test %calc-generator
  (finishes
    (loop for modulus from 2 to 3000
          for generator = (%calc-generator modulus)
          when (sb-int:positive-primep modulus)
          do (assert (generator-p generator modulus))))
  (is (= 3 (%calc-generator 998244353))))

(test ntt/random
  (let ((state (sb-ext:seed-random-state 0)))
    (finishes
      (dotimes (_ 1000)
        (let* ((len1 (random 10 state))
               (len2 (random 10 state))
               (poly1 (make-random-polynomial len1 state +ntt-mod+))
               (poly2 (make-random-polynomial len2 state +ntt-mod+)))
          (assert (equalp (poly-mult poly1 poly2 +ntt-mod+)
                          (convolve poly1 poly2))))))
    (finishes
      (dotimes (_ 1000)
        (let* ((len1 (random 10 state))
               (len2 (random 10 state))
               (poly1 (make-random-polynomial len1 state +ntt-mod2+))
               (poly2 (make-random-polynomial len2 state +ntt-mod2+)))
          (assert (equalp (poly-mult poly1 poly2 +ntt-mod2+)
                          (convolve2 poly1 poly2))))))))
