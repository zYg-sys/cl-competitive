(defpackage :cp/matrix-rotate
  (:use :cl)
  (:export #:matrix-rotate #:matrix-transpose)
  (:documentation "Provides rotation and transposition of matrix."))
(in-package :cp/matrix-rotate)

(defun matrix-rotate (matrix rot)
  "Counterclockwise rotates a 2-dimensional array by 90 * ROT degrees. This
function is non-destructive."
  (declare ((array * (* *)) matrix)
           (integer rot))
  (destructuring-bind (h w) (array-dimensions matrix)
    (declare ((integer 0 #.most-positive-fixnum) h w))
    (let* ((rot (mod rot 4))
           (new-h (if (evenp rot) h w))
           (new-w (if (evenp rot) w h))
           (res (make-array (list new-h new-w) :element-type (array-element-type matrix))))
      (declare ((integer 0 3) rot))
      (case rot
        (0 (dotimes (i h)
             (dotimes (j w)
               (setf (aref res i j) (aref matrix i j)))))
        (1 (dotimes (i h)
             (dotimes (j w)
               (setf (aref res (- w 1 j) i) (aref matrix i j)))))
        (2 (dotimes (i h)
             (dotimes (j w)
               (setf (aref res (- h 1 i) (- w 1 j)) (aref matrix i j)))))
        (3 (dotimes (i h)
             (dotimes (j w)
               (setf (aref res j (- h 1 i)) (aref matrix i j))))))
      res)))

(declaim (inline matrix-transpose))
(defun matrix-transpose (matrix)
  (declare ((array * (* *)) matrix))
  (destructuring-bind (h w) (array-dimensions matrix)
    (declare ((integer 0 #.most-positive-fixnum) h w))
    (let ((res (make-array (list w h) :element-type (array-element-type matrix))))
      (dotimes (i h)
        (dotimes (j w)
          (setf (aref res j i) (aref matrix i j))))
      res)))
