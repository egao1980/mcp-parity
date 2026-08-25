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
     (asdf:load-system "mcp-backend-stdio"))))

(mcp-backend-stdio:use-stdio-mcp-backend)

(let ((server (make-instance 'mcp-protocol:mcp-server
                             :name "mcp-parity-lisp" :version "0.1.0"
                             :instructions "stdio dual-era parity fixture")))
  (mcp-protocol:register-tool
   server
   (mcp-protocol:make-mcp-tool
    "echo" :description "echo msg"
    :input-schema (mcp-protocol:json-object
                   "type" "object"
                   "properties" (mcp-protocol:json-object
                                 "msg" (mcp-protocol:json-object "type" "string"))
                   "required" #("msg"))
    :handler (lambda (args)
               (mcp-protocol:tool-result
                (list (mcp-protocol:make-text-content
                       (or (mcp-protocol:param args "msg") "")))))))
  (mcp-protocol:register-resource
   server
   (mcp-protocol:make-mcp-resource
    "memo://hi" :name "hi"
    :handler (lambda (res)
               (declare (ignore res))
               "hello")))
  (mcp-protocol:register-prompt
   server
   (mcp-protocol:make-mcp-prompt
    "greet" :description "say hi"
    :handler (lambda (args)
               (declare (ignore args))
               (mcp-protocol:json-object
                "messages"
                (vector (mcp-protocol:json-object
                         "role" "user"
                         "content" (mcp-protocol:make-text-content "say hi")))))))
  (mcp-protocol:mcp-serve server)
  (uiop:quit 0))
