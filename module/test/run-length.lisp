(defpackage :cp/test/run-length
  (:use :cl :fiveam :cp/run-length)
  (:import-from :cp/test/base #:base-suite))
(in-package :cp/test/run-length)
(in-suite base-suite)

(test map-run-length
  ;; vector
  (map-run-length (lambda (x y) (error "Must not be called.")) #())
  (let ((result '((3 . 1))))
    (map-run-length (lambda (x y) (assert (equal (cons x y) (pop result)))) #(3)))
  (let ((result '((1 . 1) (2 . 2) (3 . 2) (1 . 3) (2 . 2))))
    (map-run-length (lambda (x y) (assert (equal (cons x y) (pop result))))
                    #(1 2 2 3 3 1 1 1 2 2)))
  (map-run-length (lambda (x y) (assert (and (= 0 x) (= 3 y))))
                  #(0 0.0 0)
                  :test #'=)
  ;; list
  (map-run-length (lambda (x y) (error "Must not be called.")) nil)
  (let ((result '((3 . 1))))
    (map-run-length (lambda (x y) (assert (equal (cons x y) (pop result)))) '(3)))
  (let ((result '((1 . 1) (2 . 2) (3 . 2) (1 . 3) (2 . 2))))
    (map-run-length (lambda (x y) (assert (equal (cons x y) (pop result))))
                    '(1 2 2 3 3 1 1 1 2 2)))
  (map-run-length (lambda (x y) (assert (and (= 0 x) (= 3 y))))
                  '(0 0.0 0)
                  :test #'=))
