(defpackage :cp/test/binary-heap
  (:use :cl :fiveam :cp/binary-heap)
  (:import-from :cp/test/base #:base-suite))
(in-package :cp/test/binary-heap)
(in-suite base-suite)

(define-binary-heap sheap
  :order #'<
  :element-type (unsigned-byte 32))

(test binary-heap/static-order/hand
  (let ((h (make-sheap 7)))
    (is (= 0 (sheap-count h)))
    (dolist (x '(6 18 22 15 27 9 11))
      (sheap-push x h))
    (is (= 6 (sheap-peek h)))
    (is (= 7 (sheap-count h)))
    (sheap-push 0 h)
    (is (= 8 (sheap-count h)))
    (is (= 0 (sheap-peek h)))
    (sheap-push 7 h)
    (is (= 9 (sheap-count h)))
    (is (= 0 (sheap-peek h)))
    (is (zerop (sheap-pop h)))
    (is (= 8 (sheap-count h)))
    (is (= 6 (sheap-peek h)))
    (is (equal '(6 7 9 11 15 18 22 27)
               (loop repeat 8 collect (sheap-pop h))))
    (is (sheap-empty-p h))
    (signals heap-empty-error (sheap-pop h))
    (sheap-push 3 h)
    (is (= 3 (sheap-peek h)))
    (is (not (sheap-empty-p h)))
    (sheap-clear h)
    (is (sheap-empty-p h))
    (sheap-clear h)
    (is (sheap-empty-p h)))
  (is (typep (sheap-data (make-sheap 10))
             '(simple-array (unsigned-byte 32) (*)))))

(define-binary-heap dheap
  :element-type base-char)

(test binary-heap/dynamic-order/hand
  (let ((h (make-dheap 5 #'char<)))
    (is (= 0 (dheap-count h)))
    (dolist (x '(#\a #\c #\e #\b #\z #\d))
      (dheap-push x h))
    (is (char= #\a (dheap-peek h)))
    (is (= 6 (dheap-count h)))
    (dheap-push #\a h)
    (is (= 7 (dheap-count h)))
    (is (char= #\a (dheap-peek h)))
    (is (char= #\a (dheap-pop h)))
    (is (= 6 (dheap-count h)))
    (is (char= #\a (dheap-peek h)))
    (is (equal '(#\a #\b #\c #\d #\e #\z)
               (loop repeat 6 collect (dheap-pop h))))
    (is (dheap-empty-p h))
    (signals heap-empty-error (dheap-pop h))
    (dheap-push #\m h)
    (is (char= #\m (dheap-peek h)))
    (is (not (dheap-empty-p h)))
    (dheap-clear h)
    (is (dheap-empty-p h))
    (dheap-clear h)
    (is (dheap-empty-p h))
    (is (eq #'char< (dheap-order h)))))
