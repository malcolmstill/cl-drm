
(in-package :drm)

(define-foreign-library libdrm
  (t (:default "libdrm")))

(use-foreign-library libdrm)

(defcenum mode-connection
  (:connected 1)
  (:disconnected 2)
  (:unknown-connection 3))

(defcenum mode-subpixel
  (:unknown 1)
  :horizontal-rgb
  :horizontal-bgr
  :vertical-rgb
  :vertical-bgr
  :none)

(defcstruct mode-res 
  (count-fbs :int)
  (fbs (:pointer :uint32))
  (count-crtcs :int)
  (crtcs (:pointer :uint32))
  (count-connectors :int)
  (connectors (:pointer :uint32))
  (count-encoders :int)
  (encoders :uint32)
  (min-width :uint32)
  (max-width :uint32)
  (min-height :uint32)
  (max-height :uint32))

(defcstruct mode-mode-info
  (clock :uint32)
  (hdisplay :uint16)
  (hsync-start :uint16)
  (hsync-end :uint16)
  (htotal :uint16)
  (hskew :uint16)
  (vdisplay :uint16)
  (vsync-start :uint16)
  (vsync-end :uint16)
  (vtotal :uint16)
  (vskew :uint16)
  (vrefresh :uint16)
  (flags :uint32)
  (type :uint32)
  (name :char :count 32))

(defcstruct mode-connector
  (connector-id :uint32)
  (encoder-id :uint32)
  (connector-type :uint32)
  (connector-type-id :uint32)
  (connection mode-connection)
  (mm-width :uint32)
  (mm-height :uint32)
  (subpixel mode-subpixel)
  (count-modes :int) ;; defined as just int
  (modes (:pointer (:struct mode-mode-info)))
  (count-props :int) ;; defined as just int
  (props (:pointer :uint32))
  (prop-values (:pointer :uint64))
  (count-encodes :int)
  (encoders (:pointer :uint32)))

(defcstruct mode-encoder
  (encoder-id :uint32)
  (encoder-type :uint32)
  (crtc-id :uint32)
  (possible-crtcs :uint32)
  (possible-clones :uint32))
  
(defcfun ("drmModeGetEncoder" mode-get-encoder) :pointer
  (fd :int)
  (encoder-id :uint32))

(defcfun ("drmModeGetResources" mode-get-resources) (:pointer (:struct mode-res))
  (fd :int))

(defcfun ("drmModeGetConnector" mode-get-connector) (:pointer (:struct mode-connector))
  (fd :int)
  (connector-id :uint32))

(defun find-connectors (fd resources)
  (let ((count (foreign-slot-value resources '(:struct mode-res) 'count-connectors))
	(ptr (foreign-slot-value resources '(:struct mode-res) 'connectors)))
    (mapcar (lambda (connector-id)
	      (mode-get-connector fd connector-id))
	    (loop :for i :from 0 :to (- count 1)
	       :collecting (mem-aref ptr :uint32 i)))))

(defun first-connected (connectors)
  (loop :for connector :in connectors
     :when (eql (foreign-slot-value connector '(:struct mode-connector) 'connection) :connected)
     :return connector))

(defun find-encoder (fd connector)
  (let ((encoder-id (foreign-slot-value connector '(:struct mode-connector) 'encoder-id)))
    (if (zerop encoder-id)
	(error "No encoder found")
	(mode-get-encoder fd encoder-id))))

(defun get-modes (connector)
  (let ((count-modes (foreign-slot-value connector '(:struct mode-connector)  'count-modes))
	(modes (foreign-slot-value connector '(:struct mode-connector) 'modes)))
    (loop :for i :from 0 :to (- count-modes 1)
       :collecting (mem-aptr modes '(:struct mode-mode-info) i))))

(defcstruct mode-crtc
  (crtc-id :uint32)
  (buffer-id :uint32)
  (x :uint32)
  (y :uint32)
  (width :uint32)
  (height :uint32)
  (mode-valid :int)
  (mode (:struct mode-mode-info))
  (gamma-size :int))

(defcfun ("drmModeGetCrtc" mode-get-crtc) (:pointer (:struct mode-crtc))
  (fd :int)
  (crtc-id :uint32))

(defcfun ("drmModeFreeEncoder" mode-free-encoder) :void
  (encoder (:pointer (:struct mode-encoder))))

(defcfun ("drmModeFreeConnector" mode-free-connector) :void
  (connector (:pointer (:struct mode-connector))))

(defcfun ("drmModeFreeResources" mode-free-resources) :void
  (resources (:pointer (:struct mode-res))))

(defcfun ("drmModeFreeCrtc" mode-free-crtc) :void
  (crtc (:pointer (:struct mode-crtc))))

(defcfun ("drmModeSetCrtc" mode-set-crtc) :int
  (fd :int)
  (crtc-id :uint32)
  (buffer-id :uint32)
  (x :uint32)
  (y :uint32)
  (connectors (:pointer :uint32))
  (count :int)
  (mode (:pointer (:struct mode-mode-info))))

(defclass display-config ()
  ((connector-id :accessor connector-id :initarg :connector-id :initform nil)
   (mode-info :accessor mode-info :initarg :mode-info :initform nil)
   (crtc :accessor crtc :initarg :crtc :initform nil)))

(defun find-display-configuration (fd)
  (let* ((resources (mode-get-resources fd))
	 (connector (first-connected (find-connectors fd resources)))
	 (connector-id (foreign-slot-value connector '(:struct mode-connector) 'connector-id))
	 (mode (first (get-modes connector)))
	 (encoder (find-encoder fd connector))
	 (crtc (mode-get-crtc fd (foreign-slot-value encoder '(:struct mode-encoder) 'crtc-id))))
    (format t "resolution: ~dx~d~%"
	    (foreign-slot-value mode '(:struct mode-mode-info) 'hdisplay)
	    (foreign-slot-value mode '(:struct mode-mode-info) 'vdisplay))
    ;(mode-free-encoder encoder)
    ;(mode-free-connector connector)
    ;; BUG? (mode-free-connector connector)
    ;; if we free the connector the mode is corrupted on return from this function
    ;(mode-free-resources resources)
    (make-instance 'display-config
		   :connector-id connector-id
		   :mode-info mode
		   :crtc crtc)))

(defcfun ("drmModeAddFB" mode-add-framebuffer) :int
  (fd :int)
  (width :uint32)
  (height :uint32)
  (depth :uint8)
  (bpp :uint8)
  (pitch :uint32)
  (bo-handle :uint32)
  (buf-id (:pointer :uint32)))

(defcfun ("drmModeRmFB" mode-remove-framebuffer) :int
  (fd :int)
  (buffer-id :uint32))

(defcfun ("drmModePageFlip" mode-page-flip) :int
  (fd :int)
  (crtc-id :uint32)
  (fb-id :uint32)
  (flags :uint32)
  (user-data :pointer))

;; void (*vblank_handler)(int fd, unsigned int sequence, unsigned int tv_sec, unsigned int tv_usec, void *user_data);
;; void (*page_flip_handler)(int fd, unsigned int sequence, unsigned int tv_sec, unsigned int tv_usec, void *user_data);
(defcstruct event-context
  (version :int)
  (vblank-handler :pointer) 
  (page-flip-handler :pointer))

(defcfun ("drmHandleEvent" handle-event) :int
  (fd :int)
  (event-context (:pointer (:struct event-context))))
