(defpackage #:text-sub
  (:use #:cl
	#:application
	#:utility))
(in-package #:text-sub)

(deflazy text-data ()
  (glhelp::make-gl-framebuffer 256 256))

(deflazy text-shader-source ()
  (glslgen:ashader
   :version 120
   :vs
   (glslgen2::make-shader-stage
    :out '((texcoord-out "vec2"))
    :in '((position "vec4")
	  (texcoord "vec2")
	  (projection-model-view "mat4"))
    :program
    '(defun "main" void ()
      (= "gl_Position" (* projection-model-view position))
      (= texcoord-out texcoord)))
   :frag
   (glslgen2::make-shader-stage
    :in '((texcoord "vec2")
	  (indirection "sampler2D")
	  (text-data "sampler2D")
	  (font-atlas ("vec4" 256))
	  (color-atlas ("vec4" 256))
	  (font-texture "sampler2D"))
    :program
    '(defun "main" void ()

	 ;;;indirection
      (/**/ vec4 ind)
      (= ind ("texture2D" indirection texcoord))

      (/**/ vec4 raw)
      (= raw ("texture2D" text-data
	      (|.| ind "ba")))

      ;;where text changes go
      (/**/ ivec3 chardata)
      (= chardata
       (ivec3 (* 255.0 raw)))

      ;;font atlass coordinates
      (/**/ vec4 fontdata)
      (= fontdata
       ([]
	font-atlas
	(|.| chardata "r")))

      ;;font lookup
      (/**/ vec4 pixcolor)
      (= pixcolor
       ("texture2D"
	font-texture
	(mix (|.| fontdata "xy")
	     (|.| fontdata "zw")
					;(vec2 0.5 0.5)
	     (|.| ind "rg")
	     )))
      
      (/**/ vec4 fin)
      (= fin
       (mix
	([] color-atlas (|.| chardata "g"))
	([] color-atlas (|.| chardata "b"))
	pixcolor))
      (= (|.| :gl-frag-color "rgb")
       (|.| fin "rgb"))
      (= (|.| :gl-frag-color "a")
       (*
	(|.| fin "a")
	(|.| raw "a")))
      ))
   :attributes
   '((position . 0) 
     (texcoord . 2))
   :varyings
   '((texcoord-out . texcoord))
   :uniforms
   '((:pmv (:vertex-shader projection-model-view))
     (indirection (:fragment-shader indirection))
     (text-data (:fragment-shader text-data))
     (color-data (:fragment-shader color-atlas))
     (font-data (:fragment-shader font-atlas))
     (font-texture (:fragment-shader font-texture)))))

(defvar *this-directory* (filesystem-util:this-directory))
(deflazy font-png ()
  (let ((array
	 (opticl:read-png-file
	  (filesystem-util:rebase-path #P"font.png"
				       *this-directory*))))
    (destructuring-bind (w h) (array-dimensions array)
      (let ((new
	     (make-array (list w h 4) :element-type '(unsigned-byte 8))))
	(dobox ((width 0 w)
		(height 0 h))
	       (let ((value (aref array width height)))
		 (dotimes (i 4)
		   (setf (aref new width height i) value))))
	new))))
(deflazy font-texture (font-png)
  (prog1
      (make-instance
       'glhelp::gl-texture
       :handle
       (glhelp:pic-texture
	font-png
	:rgba
	))
    (glhelp:apply-tex-params
     (quote ((:texture-min-filter . :nearest)
	     (:texture-mag-filter . :nearest)
	     (:texture-wrap-s . :repeat)
	     (:texture-wrap-t . :repeat))))))

(defun per-frame (session)
  (declare (ignorable session))
  (get-fresh 'render-normal-text-indirection)
  (get-fresh 'color-lookup)
  (render-stuff))

(defparameter *trans* (nsb-cga:scale* (/ 1.0 128.0) (/ 1.0 128.0) 1.0))
(defun retrans (x y &optional (trans *trans*))
  (setf (aref trans 12) (/ x 128.0)
	(aref trans 13) (/ y 128.0))
  trans)

(defparameter *numbuf* (make-array 0 :fill-pointer 0 :adjustable t :element-type 'character))
(defun render-stuff ()
  (gl:bind-framebuffer :framebuffer (glhelp::handle (getfnc 'text-data)))
  (application::%set-render-area 0 0 256 256)
  (gl:clear :color-buffer-bit)
  (gl:disable :depth-test)
  (let ((program (getfnc 'flat-shader)))
    (glhelp::use-gl-program program)
    (glhelp:with-uniforms
	uniform program
      (labels ((rebase (x y)
		 (gl:uniform-matrix-4fv
		  (uniform :pmv)
		  (retrans x y)
		  nil)))
	(flet ((pos (x y z)
		 (vertex
		  x y z 1.0))
	       (value (x y z)
		 (color
		  x y z 1.0)))
	  (setf (fill-pointer *numbuf*) 0)
	  (with-output-to-string (stream *numbuf* :element-type 'character)
	    (princ (get-internal-real-time) stream)
	    *numbuf*)
	  (rebase -128.0 -128.0)
	  (gl:point-size 1.0)
	  (let ((count 0))
	    (dotimes (x 16)
	      (dotimes (y 16)
		(let ((val (byte/255 count)))
		  (value val
			 val
			 val))
		(pos (floatify x)
		     (floatify y)
		     0.0)
		(incf count))))
					;   (basic::render-terminal 0 24)
	  (let ((bgcol (byte/255 (color-rgba 3 3 3 3)))
		(fgcol (byte/255 (color-rgba 0 0 0 3))))
	    ((lambda (x y string)
	       (let ((start x))
		 (let ((len (length string)))
		   (dotimes (index len)
		     (let ((char (aref string index)))
		       (cond ((char= char #\Newline)
			      (setf x start)
			      (decf y))
			     (t
			      (value (byte/255 (char-code char))
				     bgcol
				     fgcol)
			      (pos (floatify x)
				   (floatify y)
				   0.0)
			      
			      (setf x (1+ x))))))
		   len)))
	     10.0 10.0 *numbuf*))))))
 ; #+nil
  (gl:with-primitives :points
    (mesh))
  (let ((program (getfnc 'text-shader)))
    (glhelp::use-gl-program program)
    (glhelp:with-uniforms uniform program
      (gl:uniform-matrix-4fv
       (uniform :pmv)
       (load-time-value (nsb-cga:identity-matrix))
       nil)
      (progn
	(gl:uniformi (uniform 'indirection) 0)
	(glhelp::set-active-texture 0)
	(gl:bind-texture :texture-2d
			 (glhelp::texture (getfnc 'indirection))
			 ))
      (progn
	(gl:uniformi (uniform 'font-texture) 2)
	(glhelp::set-active-texture 2)
	(gl:bind-texture :texture-2d
			 (glhelp::handle (getfnc 'font-texture))
			 ))

      (progn
	(gl:uniformi (uniform 'text-data) 1)
	(glhelp::set-active-texture 1)
	(gl:bind-texture :texture-2d
			 (glhelp::texture (getfnc 'text-data))
			 )))
    
    (glhelp::bind-default-framebuffer)
    (application::%set-render-area 0 0 (getfnc 'application::w) (getfnc 'application::h))
    (gl:enable :blend)
    (gl:blend-func :src-alpha :one-minus-src-alpha)
    (gl:call-list (glhelp::handle (getfnc 'fullscreen-quad)))
    ))

(deflazy fullscreen-quad ()
  (let ((a (scratch-buffer:my-iterator))
	(b (scratch-buffer:my-iterator))
	(len 0))
    (iterator:bind-iterator-out
     (pos single-float) a
     (iterator:bind-iterator-out
      (tex single-float) b
      (etouq (cons 'pos (axis-aligned-quads:quadk+ 0.5 '(-1.0 1.0 -1.0 1.0))))
      (etouq
       (cons 'tex
	     (axis-aligned-quads:duaq 1 nil '(0.0 1.0 0.0 1.0)))))
     (incf len 4)
     )
    (make-instance
     'glhelp::gl-list
     :handle
     (glhelp:with-gl-list
       (gl:with-primitives :quads
	 (scratch-buffer:flush-my-iterator a
	   (scratch-buffer:flush-my-iterator b
	     ((lambda (times a b)
		(iterator:bind-iterator-in
		 (xyz single-float) a
		 (iterator:bind-iterator-in
		  (tex single-float) b
		  (dotimes (x times)
		    (%gl:vertex-attrib-2f 2 (tex) (tex))
		    (%gl:vertex-attrib-4f 0 (xyz) (xyz) (xyz) 1.0)))))
	      len a b))))))))

;;;;4 shades each of r g b a 0.0 1/3 2/3 and 1.0
(defun color-fun (color)
  (let ((one-third (etouq (coerce 1/3 'single-float))))
    (macrolet ((k (num)
		 `(* one-third (floatify (ldb (byte 2 ,num) color)))))
      (values (k 0)
	      (k 2)
	      (k 4)
	      (k 6)))))
(defun color-rgba (r g b a)
  (dpb a (byte 2 6)
       (dpb b (byte 2 4)
	    (dpb g (byte 2 2)
		 (dpb r (byte 2 0) 0)))))

(defmacro with-foreign-array ((var lisp-array type &optional (len (gensym)))
			      &rest body)
  (with-gensyms (i)
    (once-only (lisp-array)
      `(let ((,len (array-total-size ,lisp-array)))
	 (cffi:with-foreign-object (,var ,type ,len)
	   (dotimes (,i ,len)
	     (setf (cffi:mem-aref ,var ,type ,i)
		   (row-major-aref ,lisp-array ,i)))
	   ,@body)))))
(defparameter *16x16-tilemap* (rectangular-tilemap:regular-enumeration 16 16))
(defparameter *terminal256color-lookup* (make-array (* 4 256) :element-type 'single-float))
(defun write-to-color-lookup (color-fun)
  (let ((arr *terminal256color-lookup*))
    (dotimes (x 256)
      (let ((offset (* 4 x)))
	(multiple-value-bind (r g b a) (funcall color-fun x) 
	  (setf (aref arr (+ offset 0)) r)
	  (setf (aref arr (+ offset 1)) g)
	  (setf (aref arr (+ offset 2)) b)
	  (setf (aref arr (+ offset 3)) (if a a 1.0)))))
    arr))
(write-to-color-lookup 'color-fun)
(defun change-color-lookup (color-fun)
  (application::reload 'color-lookup)
  (write-to-color-lookup color-fun))
(deflazy color-lookup (text-shader)
  (glhelp::use-gl-program text-shader)
  (glhelp:with-uniforms uniform text-shader
    (with-foreign-array (var *terminal256color-lookup* :float len)
      (%gl:uniform-4fv (uniform 'color-data)
		       (/ len 4)
		       var))))
(deflazy text-shader (text-shader-source) 
  (let ((shader (glhelp::create-gl-program text-shader-source)))
    (glhelp::use-gl-program shader)
    (glhelp:with-uniforms uniform shader
      (with-foreign-array (var *16x16-tilemap* :float len)
	(%gl:uniform-4fv (uniform 'font-data)
			 (/ len 4)
			 var)))
    shader))

;;vertex = 0
;;tex-coord = 2
;;color = 3
(defparameter *vertex-scratch* (scratch-buffer:my-iterator))
(defparameter *tex-coord-scratch* (scratch-buffer:my-iterator))
(defparameter *color-scratch* (scratch-buffer:my-iterator))

(defun vertex (&optional (x 0.0) (y 0.0) (z 0.0) (w 1.0))
  (iterator:bind-iterator-out
   (emit single-float) *vertex-scratch*
   (emit x y z w)))
(defun tex-coord (&optional (x 0.0) (y 0.0) (z 0.0) (w 1.0))
  (iterator:bind-iterator-out
   (emit single-float) *tex-coord-scratch*
   (emit x y z w)))
(defun color (&optional (x 0.0) (y 0.0) (z 0.0) (w 1.0))
  (iterator:bind-iterator-out
   (emit single-float) *color-scratch*
   (emit x y z w)))
(eval-always
  (defparameter *default-attrib-locations*
    '((*vertex-scratch* 0)
      (*tex-coord-scratch* 2)
      (*color-scratch* 3)))
  (defun gen-mesher (&optional (items *default-attrib-locations*))
    (let ((sorted (sort (copy-list items) #'< :key #'second)))
      (map-into sorted (lambda (x) (cons (gensym) x)) sorted)
      (let ((first (first sorted))
	    (times-var (gensym "TIMES"))
	    (flushes nil)
	    (binds nil)
	    (attribs nil)
	    (names nil))
	(dolist (item sorted)
	  (destructuring-bind (name form num) item
	    (push `(scratch-buffer:flush-my-iterator ,name) flushes)
	    (push `(,name ,form) names)
	    (let ((emit (gensym "EMIT")))
	      (push `(iterator:bind-iterator-in
		      (,emit single-float) ,name) binds)
	      (push `(%gl:vertex-attrib-4f ,num (,emit) (,emit) (,emit) (,emit))
		    attribs))))
	(let ((header1
	       `(let ,names))
	      (header2
	       `(let ((,times-var (/ (scratch-buffer:iterator-fill-pointer ,(first first)) 4))))))
	  (%nest
	   (nconc
	    (list
	     header1
	     header2)
	    flushes
	    binds
	    (list
	     `(dotimes (x ,times-var)
		,(cons 'progn attribs))))))))))
(defmacro gen (name &rest items)
  (let (acc)
    (dolist (item items)
      (let* ((string (symbol-name item))
	     (namesake (find-symbol (concatenate 'string "*" string "-SCRATCH*"))))
	(when namesake
	  (push (assoc namesake *default-attrib-locations*) acc))))
    `(defun ,name ()
       ,(gen-mesher acc))))
(gen mesh vertex color)

(deflazy flat-shader-source ()
  (glslgen:ashader
   :version 120
   :vs
   (glslgen2::make-shader-stage
    :out '((value-out "vec4"))
    :in '((position "vec4")
	  (value "vec4")
	  (projection-model-view "mat4"))
    :program
    '(defun "main" void ()
      (= "gl_Position" (* projection-model-view position))
      (= value-out value)))
   :frag
   (glslgen2::make-shader-stage
    :in '((value "vec4"))
    :program
    '(defun "main" void ()	 
      (= :gl-frag-color value)))
   :attributes
   '((position . 0) 
     (value . 3))
   :varyings
   '((value-out . value))
   :uniforms
   '((:pmv (:vertex-shader projection-model-view)))))
(deflazy flat-shader (flat-shader-source)
  (glhelp::create-gl-program flat-shader-source))

;;;;;;;;;;;;;;;;;;;;
(deflazy indirection-shader-source ()
  (glslgen:ashader
   :version 120
   :vs
   (glslgen2::make-shader-stage
    :out '((texcoord-out "vec2"))
    :in '((position "vec4")
	  (texcoord "vec2")
	  (projection-model-view "mat4"))
    :program
    '(defun "main" void ()
      (= "gl_Position" (* projection-model-view position))
      (= texcoord-out texcoord)))
   :frag
   (glslgen2::make-shader-stage
    :in '((texcoord "vec2")
	  (size "vec2"))
    :program
    '(defun "main" void ()
      ;;rg = fraction
      ;;ba = text lookup
      (/**/ vec2 foo)
      (= foo (/ (floor (* texcoord size))
	      (vec2 255.0)))	 
      (/**/ vec2 bar)
      (= bar
       (fract
	(* 
	 texcoord
	 size)))         
      (/**/ vec4 pixcolor) ;;font lookup
      (= (|.| pixcolor "rg") bar)       ;;fraction
      (= (|.| pixcolor "ba") foo)      ;;text lookup 
      (= :gl-frag-color pixcolor)))
   :attributes
   '((position . 0) 
     (texcoord . 2))
   :varyings
   '((texcoord-out . texcoord))
   :uniforms
   '((:pmv (:vertex-shader projection-model-view))
     (size (:fragment-shader size)))))
(deflazy indirection-shader (indirection-shader-source)
  (glhelp::create-gl-program indirection-shader-source))

;;;;;;;;;;;;;;;;
(defparameter *block-height* 16.0)
(defparameter *block-width* 8.0)
(defparameter *indirection-width* 0)
(defparameter *indirection-height* 0)
(deflazy indirection ()
  (glhelp::make-gl-framebuffer
   *indirection-width*
   *indirection-height*))
;;;Round up to next power of two
(defun power-of-2-ceiling (n)
  (ash 1 (ceiling (log n 2))))
(deflazy render-normal-text-indirection ((application::w w) (application::h h))
  (let ((upw (power-of-2-ceiling w))
	(uph (power-of-2-ceiling h))
	(refract (getfnc 'indirection-shader)))
    (glhelp::use-gl-program refract)
    (glhelp:with-uniforms uniform refract
      (gl:uniform-matrix-4fv
       (uniform :pmv)
       (load-time-value (nsb-cga:identity-matrix))
       nil)
      (gl:uniformf (uniform 'size)
		   (/ w *block-width*)
		   (/ h *block-height*)))
    (gl:disable :cull-face)
    (gl:disable :depth-test)
    (gl:disable :blend)
    (application::%set-render-area 0 0 upw uph)
    (when (not (and (= *indirection-width* upw)
		    (= *indirection-height* uph)))
      (setf *indirection-width* upw
	    *indirection-height* uph)
      (application::reload 'indirection))
    (gl:bind-framebuffer :framebuffer (glhelp::handle (getfnc 'indirection)))
    (gl:clear :color-buffer-bit)
    (gl:call-list (glhelp::handle (getfnc 'fullscreen-quad)))))
