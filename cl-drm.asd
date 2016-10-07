;;;; cl-drm.asd

(asdf:defsystem #:cl-drm
  :description "Common Lisp bindings for libdrm"
  :author "Malcolm Still"
  :license "Specify license here"
  :depends-on (#:cffi)
  :serial t
  :components ((:file "package")
               (:file "cl-drm")))

