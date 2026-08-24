(in-package #:mcp-parity)

(defun %ensure-http-backend ()
  (or http-protocol:*http-backend*
      (setf http-protocol:*http-backend*
            (http-backend-dexador:make-dexador-backend))))

(defun %ensure-http-server ()
  (or http-server-protocol:*http-server-backend*
      (http-server-backend-hunchentoot:use-hunchentoot-backend)))

(defun %mcp-url (port)
  (format nil "http://127.0.0.1:~a/mcp" port))

(defun call-with-lisp-http-server (fn)
  (%ensure-http-server)
  (mcp-backend-streamable-http:use-streamable-http-mcp-backend)
  (let ((port (%free-port)))
    (http-server-protocol:with-server
        (s (mcp-backend-streamable-http:make-mcp-app (make-parity-server)
                                                     :path "/mcp")
           :host "127.0.0.1" :port port)
      (sleep 0.15)
      (funcall fn (%mcp-url port)))))

(defun lisp-http-talk (url)
  (%ensure-http-backend)
  (mcp-backend-streamable-http:use-streamable-http-mcp-backend)
  (let ((client (mcp-protocol:mcp-connect :url url :probe t
                                          :name "mcp-parity-lisp"
                                          :version "0.1.0")))
    (%report client)))

(defun lisp-http-lisp-server ()
  (call-with-lisp-http-server #'lisp-http-talk))

(defun lisp-http-peer-server (kind)
  (with-peer-http-server (url kind)
    (lisp-http-talk url)))

(defun foreign-http-client-talk (kind url)
  (let* ((cmd (http-client-command kind url)))
    (multiple-value-bind (out err)
        (uiop:run-program cmd
                          :output :string
                          :error-output :string
                          :ignore-error-status t)
      (let ((parsed (loop for line in (uiop:split-string out :separator '(#\newline))
                          for rec = (parse-json-line line)
                          when rec collect rec)))
        (unless parsed
          (error "foreign HTTP client ~a produced no JSON~%cmd: ~s~%stdout:~%~a~%stderr:~%~a"
                 kind cmd out err))
        (let ((rec (first (last parsed))))
          (list :era (gethash "era" rec)
                :tools (%js-tools rec)
                :echo (%js-string rec "echo")
                :resource (%js-string rec "resource")
                :prompt (%js-string rec "prompt")))))))
