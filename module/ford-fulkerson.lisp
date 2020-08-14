;;;
;;; Ford-Fulkerson
;;; (better to use Dinic's algorithm. I leave it just for my reference.)
;;;

(defpackage :cp/ford-fulkerson
  (:use :cl :cp/max-flow)
  (:export #:max-flow!))
(in-package :cp/ford-fulkerson)

(declaim (ftype (function * (values (integer 0 #.most-positive-fixnum) &optional)) %find-flow))
(defun %find-flow (graph src dest checked)
  "DFS"
  (declare (optimize (speed 3) (safety 0))
           ((integer 0 #.most-positive-fixnum) src dest)
           (simple-bit-vector checked)
           ((simple-array list (*)) graph))
  (fill checked 0)
  (labels ((dfs (vertex flow)
             (declare ((integer 0 #.most-positive-fixnum) flow))
             (setf (aref checked vertex) 1)
             (if (= vertex dest)
                 flow
                 (dolist (edge (aref graph vertex) 0)
                   (when (and (zerop (aref checked (edge-to edge)))
                              (> (edge-capacity edge) 0))
                     (let ((flow (dfs (edge-to edge) (min flow (edge-capacity edge)))))
                       (declare ((integer 0 #.most-positive-fixnum) flow))
                       (unless (zerop flow)
                         (decf (edge-capacity edge) flow)
                         (incf (edge-capacity (edge-reversed edge)) flow)
                         (return flow))))))))
    (dfs src most-positive-fixnum)))

(declaim (ftype (function * (values (mod #.most-positive-fixnum) &optional)) max-flow!))
(defun max-flow! (graph src dest)
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) src dest)
           ((simple-array list (*)) graph))
  (let ((checked (make-array (length graph) :element-type 'bit :initial-element 0))
        (result 0))
    (declare ((integer 0 #.most-positive-fixnum) result))
    (loop
      (let ((increment (%find-flow graph src dest checked)))
        (cond ((zerop increment)
               (return result))
              ((>= (+ result increment) most-positive-fixnum)
               (error 'max-flow-overflow :graph graph))
              (t
               (incf result increment)))))))