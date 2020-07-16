(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../ntt.lisp")
  (load "../polynomial.lisp"))

(use-package :test-util)

(with-test (:name ntt/manual)
  (assert (equalp #() (ntt-convolute #() #())))
  (assert (equalp #(15) (ntt-convolute #(3) #(5))))
  (assert (equalp #(998244308 17 2 998244348 1)
                  (ntt-convolute #(5 998244350 1) #(998244344 998244351 1))))
  (signals division-by-zero (ntt-inverse #()))
  (signals division-by-zero (ntt-inverse #(0 2))))

(defun make-random-polynomial (degree)
  (let ((res (make-array degree :element-type 'ntt-int :initial-element 0)))
    (dotimes (i degree res)
      (setf (aref res i) (random +ntt-mod+)))
    (let ((end (+ 1 (or (position 0 res :from-end t :test-not #'eql) -1))))
      (adjust-array res end))))

(with-test (:name ntt/random)
  (dotimes (_ 1000)
    (let* ((len1 (random 10))
           (len2 (random 10))
           (poly1 (make-random-polynomial len1))
           (poly2 (make-random-polynomial len2)))
      (assert (equalp (poly-mult poly1 poly2 +ntt-mod+)
                      (ntt-convolute poly1 poly2)))
      ;; inverse
      (when (find-if #'plusp poly1)
        (let ((res (ntt-convolute poly1 (ntt-inverse poly1))))
          (assert (= 1 (aref res 0)))
          (loop for i from 1 below len1
                do (assert (zerop (aref res i))))))
      ;; floor and mod
      (block continue
        (handler-bind ((division-by-zero (lambda (c) (declare (ignorable c))
                                           (return-from continue))))
          (let* ((p (ntt-floor poly1 poly2))
                 (q (ntt-sub poly1 p)))
            (equalp q (ntt-mod poly1 poly2)))))
      ;; multipoint eval.
      (let* ((points (make-random-polynomial (ash 1 (random 7))))
             (res1 (map 'ntt-vector (lambda (x) (poly-value poly1 x +ntt-mod+)) points))
             (res2 (multipoint-eval poly1 points)))
        (assert (equalp res1 res2))))))
