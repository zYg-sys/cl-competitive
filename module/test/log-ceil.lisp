(defpackage :cp/test/log-ceil
  (:use :cl :fiveam :cp/log-ceil)
  (:import-from :cp/test/base #:base-suite))
(in-package :cp/test/log-ceil)
(in-suite base-suite)

(test log2-ceil
  (declare (notinline log2-ceil))
  (is (= 0 (log2-ceil 0)))
  (is (= 0 (log2-ceil 1)))
  (is (= 1 (log2-ceil 1.5d0)))
  (is (= 1 (log2-ceil 2)))
  (is (= 2 (log2-ceil 2.1)))
  (is (= 2 (log2-ceil 5/2)))
  (is (= 2 (log2-ceil 4))))

(test log-ceil/manual
  (declare (notinline log-ceil))
  (signals division-by-zero (log-ceil 0 2))
  (is (= 0 (log-ceil 1 2)))
  (is (= 1 (log-ceil 1.5d0 2)))
  (is (= 1 (log-ceil 2 2)))
  (is (= 2 (log-ceil 2.1 2)))
  (is (= 2 (log-ceil 5/2 2)))
  (is (= 2 (log-ceil 4 2)))
  (signals type-error (log-ceil 4 2.1))
  (signals division-by-zero (log-ceil 0 3))
  (is (= 0 (log-ceil 1 3)))
  (is (= 1 (log-ceil 1.5d0 3)))
  (is (= 1 (log-ceil 3 3)))
  (is (= 2 (log-ceil 3.1 3)))
  (is (= 2 (log-ceil 7/2 3)))
  (is (= 3 (log-ceil 27 3))))

(test log-ceil/random
  (loop for base from 2 to 10
        do (is (loop for x from 1 to 2000
                     for log = (log-ceil x base)
                     always (and (>= (expt base log) x)
                                 (or (zerop log)
                                     (< (expt base (- log 1)) x)))))))
