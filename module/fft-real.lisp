;;;
;;; Real FFT
;;;
;;; Reference:
;;; http://www.kurims.kyoto-u.ac.jp/~ooura/fftman/ftmn2_12.html#sec2_1_2
;;;

(defpackage :cp/fft-real
  (:use :cl)
  (:export #:fft-float #:with-fixed-length-fft #:dft! #:inverse-dft! #:convolve!))
(in-package :cp/fft-real)

(deftype fft-float () 'double-float)

(declaim (inline power2-p))
(defun power2-p (x)
  "Checks if X is a power of 2."
  (zerop (logand x (- x 1))))

(defun %dft! (f)
  (declare (optimize (speed 3) (safety 0))
           ((simple-array fft-float (*)) f))
  (prog1 f
    (let ((n (length f))
          (theta (coerce (* -2 pi) 'fft-float)))
      (declare (fft-float theta))
      (assert (power2-p n))
      ;; bit-reverse ordering
      (let ((i 0))
        (declare ((integer 0 #.most-positive-fixnum) i))
        (loop for j from 1 below (- n 1)
              do (loop for k of-type (integer 0 #.most-positive-fixnum)
                          = (ash n -1) then (ash k -1)
                       while (> k (setq i (logxor i k))))
                 (when (< j i)
                   (rotatef (aref f i) (aref f j)))))
      (do* ((mh 1 m)
            (m (ash mh 1) (ash mh 1)))
           ((> m n))
        (declare ((integer 0 #.most-positive-fixnum) mh m))
        (let ((mq (ash mh -1)))
          (setq theta (/ theta 2))
          (do ((jr 0 (+ jr m)))
              ((>= jr n))
            (declare ((integer 0 #.most-positive-fixnum) jr))
            (let ((xreal (aref f (+ jr mh))))
              (setf (aref f (+ jr mh)) (- (aref f jr) xreal))
              (incf (aref f jr) xreal)))
          (do ((i 1 (+ i 1)))
              ((>= i mq))
            (declare ((integer 0 #.most-positive-fixnum) i))
            (let ((wreal (cos (* theta i)))
                  (wimag (sin (* theta i))))
              (do ((j 0 (+ j m)))
                  ((>= j n))
                (let* ((j+mh (+ j mh))
                       (j+m-i (- (+ j m) i))
                       (xreal (+ (* wreal (aref f (+ j+mh i)))
                                 (* wimag (aref f j+m-i))))
                       (ximag (- (* wreal (aref f j+m-i))
                                 (* wimag (aref f (+ j+mh i))))))
                  (declare ((integer 0 #.most-positive-fixnum) j+mh j+m-i))
                  (setf (aref f (+ j+mh i))
                        (+ (- (aref f (- j+mh i))) ximag))
                  (setf (aref f j+m-i)
                        (+ (aref f (- j+mh i)) ximag))
                  (setf (aref f (- j+mh i))
                        (+ (aref f (+ j i)) (- xreal)))
                  (incf (aref f (+ j i)) xreal))))))))))

(defun %inverse-dft! (f)
  (declare (optimize (speed 3) (safety 0))
           ((simple-array fft-float (*)) f))
  (prog1 f
    (let* ((n (length f))
           (theta (/ (coerce (* 2 pi) 'fft-float) n)))
      (declare (fft-float theta))
      (assert (power2-p n))
      (setf (aref f 0)
            (/ (aref f 0) 2))
      (setf (aref f (ash n -1))
            (/ (aref f (ash n -1)) 2))
      (do* ((m n mh)
            (mh (ash m -1) (ash m -1)))
           ((zerop mh))
        (declare ((integer 0 #.most-positive-fixnum) m mh))
        (let ((mq (ash mh -1)))
          (do ((jr 0 (+ jr m)))
              ((>= jr n))
            (declare ((integer 0 #.most-positive-fixnum) jr))
            (let ((xreal (- (aref f jr) (aref f (+ jr mh)))))
              (incf (aref f jr) (aref f (+ jr mh)))
              (setf (aref f (+ jr mh)) xreal)))
          (do ((i 1 (+ i 1)))
              ((>= i mq))
            (let ((wreal (cos (* theta i)))
                  (wimag (sin (* theta i))))
              (do ((j 0 (+ j m)))
                  ((>= j n))
                (let* ((j+mh (+ j mh))
                       (j+m-i (- (+ j m) i))
                       (xreal (- (aref f (+ j i)) (aref f (- j+mh i))))
                       (ximag (+ (aref f j+m-i) (aref f (+ j+mh i)))))
                  (declare ((integer 0 #.most-positive-fixnum) j+mh j+m-i))
                  (incf (aref f (+ j i)) (aref f (- j+mh i)))
                  (setf (aref f (- j+mh i))
                        (- (aref f j+m-i) (aref f (+ j+mh i))))
                  (setf (aref f (+ j+mh i))
                        (+ (* wreal xreal) (* wimag ximag)))
                  (setf (aref f j+m-i)
                        (- (* wreal ximag) (* wimag xreal))))))))
        (setq theta (* theta 2)))
      ;; bit-reverse ordering
      (let ((i 0))
        (declare ((integer 0 #.most-positive-fixnum) i))
        (loop for j from 1 below (- n 1)
              do (loop for k of-type (integer 0 #.most-positive-fixnum)
                          = (ash n -1) then (ash k -1)
                       while (> k (setq i (logxor i k))))
                 (when (< j i)
                   (rotatef (aref f i) (aref f j))))))))

;; For FFT of fixed length, preparing the table of cos(i*theta) and sin
;; (i*theta) will be efficient.
(defun %make-trifunc-table (n)
  (declare (optimize (speed 3) (safety 0)))
  (check-type n (integer 0 #.most-positive-fixnum))
  (assert (power2-p n))
  (let ((cos-table (make-array (ash n -2) :element-type 'fft-float))
        (sin-table (make-array (ash n -2) :element-type 'fft-float))
        (theta (/ (coerce (* 2 pi) 'fft-float) n)))
    (dotimes (i (ash n -2))
      (setf (aref cos-table i) (cos (* i theta))
            (aref sin-table i) (sin (* i theta))))
    (values cos-table sin-table)))

(defparameter *cos-table* nil)
(defparameter *sin-table* nil)

(defmacro with-fixed-length-fft (size &body body)
  "Makes FFT faster when the SIZE of target vectors is fixed in BODY. This macro
computes and holds the roots of unity for SIZE, which DFT! and INVERSE-DFT!
called in BODY automatically detects; they will signal an error when they
receive a vector of different size."
  (let ((s (gensym)))
    `(let ((,s ,size))
       (multiple-value-bind (*cos-table* *sin-table*) (%make-trifunc-table ,s)
         ,@body))))

(defun %dft-fixed-base! (f)
  (declare (optimize (speed 3) (safety 0))
           ((simple-array fft-float (*)) f))
  (prog1 f
    (let* ((n (length f))
           (cos-table *cos-table*)
           (sin-table *sin-table*)
           (factor n))
      (declare ((integer 0 #.most-positive-fixnum) factor)
               ((simple-array fft-float (*)) cos-table sin-table))
      (assert (power2-p n))
      (assert (= (ash n -2) (length cos-table)))
      ;; bit-reverse ordering
      (let ((i 0))
        (declare ((integer 0 #.most-positive-fixnum) i))
        (loop for j from 1 below (- n 1)
              do (loop for k of-type (integer 0 #.most-positive-fixnum)
                          = (ash n -1) then (ash k -1)
                       while (> k (setq i (logxor i k))))
                 (when (< j i)
                   (rotatef (aref f i) (aref f j)))))
      (do* ((mh 1 m)
            (m (ash mh 1) (ash mh 1)))
           ((> m n))
        (declare ((integer 0 #.most-positive-fixnum) mh m))
        (let ((mq (ash mh -1)))
          (setq factor (ash factor -1))
          (do ((jr 0 (+ jr m)))
              ((>= jr n))
            (declare ((integer 0 #.most-positive-fixnum) jr))
            (let ((xreal (aref f (+ jr mh))))
              (setf (aref f (+ jr mh)) (- (aref f jr) xreal))
              (incf (aref f jr) xreal)))
          (do ((i 1 (+ i 1)))
              ((>= i mq))
            (declare ((integer 0 #.most-positive-fixnum) i))
            (let* ((index (the fixnum (* factor i)))
                   (wreal (aref cos-table index))
                   (wimag (- (aref sin-table index))))
              (do ((j 0 (+ j m)))
                  ((>= j n))
                (let* ((j+mh (+ j mh))
                       (j+m-i (- (+ j m) i))
                       (xreal (+ (* wreal (aref f (+ j+mh i)))
                                 (* wimag (aref f j+m-i))))
                       (ximag (- (* wreal (aref f j+m-i))
                                 (* wimag (aref f (+ j+mh i))))))
                  (declare ((integer 0 #.most-positive-fixnum) j+mh j+m-i))
                  (setf (aref f (+ j+mh i))
                        (+ (- (aref f (- j+mh i))) ximag))
                  (setf (aref f j+m-i)
                        (+ (aref f (- j+mh i)) ximag))
                  (setf (aref f (- j+mh i))
                        (+ (aref f (+ j i)) (- xreal)))
                  (incf (aref f (+ j i)) xreal))))))))))

(defun %inverse-dft-fixed-base! (f)
  (declare (optimize (speed 3) (safety 0))
           ((simple-array fft-float (*)) f))
  (prog1 f
    (let* ((n (length f))
           (cos-table *cos-table*)
           (sin-table *sin-table*)
           (factor 1))
      (declare ((integer 0 #.most-positive-fixnum) factor)
               ((simple-array fft-float (*)) cos-table sin-table))
      (assert (power2-p n))
      (assert (= (ash n -2) (length cos-table)))
      (setf (aref f 0)
            (/ (aref f 0) 2))
      (setf (aref f (ash n -1))
            (/ (aref f (ash n -1)) 2))
      (do* ((m n mh)
            (mh (ash m -1) (ash m -1)))
           ((zerop mh))
        (declare ((integer 0 #.most-positive-fixnum) m mh))
        (let ((mq (ash mh -1)))
          (do ((jr 0 (+ jr m)))
              ((>= jr n))
            (declare ((integer 0 #.most-positive-fixnum) jr))
            (let ((xreal (- (aref f jr) (aref f (+ jr mh)))))
              (incf (aref f jr) (aref f (+ jr mh)))
              (setf (aref f (+ jr mh)) xreal)))
          (do ((i 1 (+ i 1)))
              ((>= i mq))
            (let* ((index (the fixnum (* factor i)))
                   (wreal (aref cos-table index))
                   (wimag (aref sin-table index)))
              (do ((j 0 (+ j m)))
                  ((>= j n))
                (let* ((j+mh (+ j mh))
                       (j+m-i (- (+ j m) i))
                       (xreal (- (aref f (+ j i)) (aref f (- j+mh i))))
                       (ximag (+ (aref f j+m-i) (aref f (+ j+mh i)))))
                  (declare ((integer 0 #.most-positive-fixnum) j+mh j+m-i))
                  (incf (aref f (+ j i)) (aref f (- j+mh i)))
                  (setf (aref f (- j+mh i))
                        (- (aref f j+m-i) (aref f (+ j+mh i))))
                  (setf (aref f (+ j+mh i))
                        (+ (* wreal xreal) (* wimag ximag)))
                  (setf (aref f j+m-i)
                        (- (* wreal ximag) (* wimag xreal))))))))
        (setq factor (ash factor 1)))
      ;; bit-reverse ordering
      (let ((i 0))
        (declare ((integer 0 #.most-positive-fixnum) i))
        (loop for j from 1 below (- n 1)
              do (loop for k of-type (integer 0 #.most-positive-fixnum)
                          = (ash n -1) then (ash k -1)
                       while (> k (setq i (logxor i k))))
                 (when (< j i)
                   (rotatef (aref f i) (aref f j))))))))

(declaim (inline dft!))
(defun dft! (f)
  (declare ((simple-array fft-float (*)) f))
  (if (zerop (length f))
      f
      (if *cos-table*
          (%dft-fixed-base! f)
          (%dft! f))))

(declaim (inline inverse-dft!))
(defun inverse-dft! (f)
  (declare ((simple-array fft-float (*)) f))
  (prog1 f
    (let ((n (length f)))
      (unless (zerop n)
        (let ((factor (* 2 (/ (coerce n 'fft-float)))))
          (if *cos-table*
              (%inverse-dft-fixed-base! f)
              (%inverse-dft! f))
          (dotimes (i n)
            (setf (aref f i) (* (aref f i) factor))))))))

(declaim (inline convolve!))
(defun convolve! (f1 f2 &optional result-vector)
  "Returns the convolution of two vectors F1 and F2. A new vector is created when
RESULT-VECTOR is null. This function destructively modifies F1 and F2. (They can
be restored by INVERSE-DFT!.)"
  (declare ((simple-array fft-float (*)) f1 f2)
           ((or null (simple-array fft-float (*))) result-vector))
  (let ((n (length f1)))
    (assert (and (power2-p n)
                 (= n (length f2))))
    (dft! f1)
    (dft! f2)
    (let ((f (or result-vector (make-array n :element-type 'fft-float))))
      (unless (zerop n)
        (setf (aref f 0)
              (* (aref f1 0) (aref f2 0)))
        (setf (aref f (ash n -1))
              (* (aref f1 (ash n -1)) (aref f2 (ash n -1)))))
      (loop for i from 1 below (ash n -1)
            for value1 of-type fft-float
               = (- (* (aref f1 i) (aref f2 i))
                    (* (aref f1 (- n i)) (aref f2 (- n i))))
            for value2 of-type fft-float
               = (+ (* (aref f1 i) (aref f2 (- n i)))
                    (* (aref f1 (- n i)) (aref f2 i)))
            do (setf (aref f i) value1)
               (setf (aref f (- n i)) value2))
      (inverse-dft! f))))
