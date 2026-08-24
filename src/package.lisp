(defpackage #:mcp-parity
  (:use #:cl)
  (:export #:*peer-root*
           #:peers-enabled-p
           #:peer-available-p
           #:make-parity-server
           #:lisp-inprocess-talk
           #:lisp-stdio-talk
           #:foreign-client-talk
           #:catalog-ok-p
           #:tool-text
           #:prompt-text
           #:print-matrix
           #:peer-server-command
           #:lisp-server-command
           #:client-command
           #:%ensure-process-backend))

(in-package #:mcp-parity)
