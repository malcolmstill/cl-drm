;;;; package.lisp

(defpackage :drm
  (:use :common-lisp :cffi)
  (:export
   mode-set-crtc
   mode-free-crtc
   mode-add-framebuffer
   mode-remove-framebuffer
   find-display-configuration
   mode-mode-info
   mode-connector
   mode-crtc
   hdisplay
   vdisplay
   crtc-id
   mode
   x
   y
   buffer-id
   mode-info
   connector-id
   crtc
   mode-page-flip
   handle-event
   event-context
   version
   vblank-handler
   page-flip-handler))
