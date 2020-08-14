(defpackage :cp/test/reference-heap
  (:use :cl :fiveam :cp/reference-heap)
  (:import-from :cp/test/base #:base-suite))
(in-package :cp/test/reference-heap)
(in-suite base-suite)

(test heap
  (let ((h (make-heap 7 :order #'< :element-type '(unsigned-byte 32))))
    (dolist (o (list 7 18 22 15 27 9 11))
      (heap-push o h))
    (heap-push 0 h)
    (is (= 8 (heap-count h)))
    (is (= 0 (heap-pop h)))
    (is (= 7 (heap-peek h)))
    (is (equal '(7 9 11 15 18 22 27)
               (loop repeat 7 collect (heap-pop h))))
    (is (heap-empty-p h))
    (signals heap-empty-error (heap-pop h)))
  (is (typep (cp/reference-heap::heap-data (make-heap 10 :element-type 'list))
             '(simple-array list (*)))))