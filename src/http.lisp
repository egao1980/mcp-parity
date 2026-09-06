(in-package #:mcp-parity)

(defun %ensure-http-backend ()
  (%ensure-jsonrpc-codec)
  (or http-protocol:*http-backend*
      (setf http-protocol:*http-backend*
            (http-backend-dexador:make-dexador-backend))))

(defun %ensure-http-server ()
  (or http-server-protocol:*http-server-backend*
      (http-server-backend-hunchentoot:use-hunchentoot-backend)))

(defun %mcp-url (port)
  (format nil "http://127.0.0.1:~a/mcp" port))

(defun call-with-lisp-http-server (fn)
  (%ensure-jsonrpc-codec)
  (%ensure-http-server)
  (mcp-backend-streamable-http:use-streamable-http-mcp-backend)
  (let ((port (%free-port)))
    (http-server-protocol:with-server
        (s (mcp-backend-streamable-http:make-mcp-app (make-parity-server)
                                                     :path "/mcp")
           :host "127.0.0.1" :port port)
      (sleep 0.15)
      (funcall fn (%mcp-url port)))))

(defun %sync-http-protocol-version (client)
  (let ((ver (mcp-protocol:mcp-client-protocol-version client))
        (transport (mcp-protocol:mcp-client-transport client)))
    (when (and (stringp ver)
               (typep transport 'mcp-backend-streamable-http:streamable-http-rpc-transport))
      (setf (mcp-backend-streamable-http:transport-protocol-version transport) ver)))
  client)

(defun lisp-http-talk (url)
  (%ensure-http-backend)
  (mcp-backend-streamable-http:use-streamable-http-mcp-backend)
  (let ((client (%connect-parity-client :url url
                                        :name "mcp-parity-lisp"
                                        :version "0.1.0")))
    (%sync-http-protocol-version client)
    (%report client)))

(defun lisp-http-lisp-server ()
  (call-with-lisp-http-server #'lisp-http-talk))

(defun lisp-http-peer-server (kind)
  (with-peer-http-server (url kind)
    (lisp-http-talk url)))

(defun foreign-http-client-talk (kind url)
  (%run-foreign-client kind (http-client-command kind url)))
