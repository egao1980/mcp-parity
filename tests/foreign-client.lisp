(in-package #:mcp-parity/tests)

(deftest node-client-lisp-server
  (if (peer-available-p :node)
      (%catalog+schema (foreign-client-talk :node (lisp-server-command)))
      (skip "node peer not available")))

(deftest python-client-lisp-server
  (if (peer-available-p :python)
      (%catalog+schema (foreign-client-talk :python (lisp-server-command)))
      (skip "python peer not available")))

(deftest node-client-lisp-http-server
  (if (http-peer-available-p :node)
      (%catalog+schema
       (call-with-lisp-http-server
        (lambda (url) (foreign-http-client-talk :node url))))
      (skip "node HTTP peer not available")))

(deftest python-client-lisp-http-server
  (if (http-peer-available-p :python)
      (%catalog+schema
       (call-with-lisp-http-server
        (lambda (url) (foreign-http-client-talk :python url))))
      (skip "python HTTP peer not available")))
