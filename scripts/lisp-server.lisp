;;;; Minimal stdio MCP server for foreign clients. Load noise on stderr only.

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&lisp-server: ~A~%" c)
        (uiop:quit 1)))

#+sbcl (sb-ext:disable-debugger)

(defun call-with-ci-muffles (fn)
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql #'continue))
    (funcall fn))
  #-sbcl
  (funcall fn))

(defun %maybe-register-workspace ()
  "Local sibling checkout: mcp-parity lives next to mcp-backend-stdio."
  (let* ((here (uiop:pathname-directory-pathname *load-truename*))
         (ws (uiop:pathname-parent-directory-pathname
              (uiop:pathname-parent-directory-pathname here)))
         (stdio (merge-pathnames "mcp-backend-stdio/mcp-backend-stdio.asd" ws)))
    (when (probe-file stdio)
      (asdf:initialize-source-registry
       `(:source-registry (:tree ,ws) :inherit-configuration)))))

(let ((*standard-output* *error-output*)
      (*trace-output* *error-output*))
  (call-with-ci-muffles
   (lambda ()
     (%maybe-register-workspace)
     (when (asdf:find-system "cl-repository-client" nil)
       (asdf:load-system "cl-repository-client")
       (uiop:symbol-call :cl-repository-client/asdf-integration
                         :configure-asdf-source-registry)
       (uiop:symbol-call :cl-repository-client/asdf-integration
                         :load-system-init-files))
     (asdf:load-system "mcp-parity")
     (asdf:load-system "rpc-protocol-json"))))

(mcp-backend-stdio:use-stdio-mcp-backend)
(mcp-protocol:mcp-serve (mcp-parity:make-parity-server))
(uiop:quit 0)
