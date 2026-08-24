(defpackage #:mcp-parity
  (:use #:cl)
  (:export #:*peer-root*
           #:peers-enabled-p
           #:peer-available-p
           #:make-parity-server
           #:lisp-inprocess-talk
           #:lisp-stdio-talk
           #:lisp-http-talk
           #:lisp-http-lisp-server
           #:lisp-http-peer-server
           #:foreign-client-talk
           #:foreign-http-client-talk
           #:call-with-lisp-http-server
           #:with-peer-http-server
           #:http-peer-available-p
           #:catalog-ok-p
           #:tool-text
           #:prompt-text
           #:print-matrix
           #:peer-server-command
           #:lisp-server-command
           #:client-command
           #:%ensure-process-backend))

(in-package #:mcp-parity)
