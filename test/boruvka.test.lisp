(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../boruvka.lisp")
  (load "../disjoint-set.lisp"))

(in-package :cl-user)
(use-package :test-util)

(defun make-random-graph (n density)
  (let ((graph (make-array n :element-type 'list :initial-element nil)))
    (dotimes (u n)
      (loop for v from (+ u 1) below n
            for cost = (random most-positive-fixnum)
            when (<= (random 1d0) density)
            do (push (cons v cost) (aref graph u))
               (push (cons u cost) (aref graph v))))
    graph))

;; Kruskal
(defun get-mst-cost (graph maximize)
  (let* (edges
         (n (length graph))
         (dset (make-disjoint-set n))
         (res 0))
    (dotimes (u n)
      (loop for (v . cost) in (aref graph u)
            when (< u v)
            do (push (list cost u v) edges)))
    (setq edges (sort edges (if maximize #'> #'<)
                      :key #'car))
    (loop for (cost u v) in edges
          unless (ds-connected-p dset u v)
          do (incf res cost)
             (ds-unite! dset u v))
    res))

(with-test (:name boruvka)
  ;; empty graph
  (multiple-value-bind (cost e1 e2) (boruvka:get-mst #())
    (assert (zerop cost))
    (assert (equalp #() e1))
    (assert (equalp #() e2)))
  ;; self loop
  (multiple-value-bind (cost e1 e2) (boruvka:get-mst #(((0 . 10))))
    (assert (zerop cost))
    (assert (equalp #() e1))
    (assert (equalp #() e2)))
  ;; minimize random graph
  (dotimes (_ 500)
    (let ((graph (make-random-graph 40 (random 1.0))))
      (assert (= (get-mst-cost graph nil) (boruvka:get-mst graph)))))
  ;; maximize random graph
  (dotimes (_ 500)
    (let ((graph (make-random-graph 40 (random 1.0))))
      (assert (= (get-mst-cost graph t) (boruvka:get-mst graph :maximize t))))))
