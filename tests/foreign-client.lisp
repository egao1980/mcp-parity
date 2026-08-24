(in-package #:mcp-parity/tests)

(deftest node-client-lisp-server
  (if (peer-available-p :node)
      (ok (catalog-ok-p (foreign-client-talk :node (lisp-server-command))))
      (skip "node peer not available")))

(deftest python-client-lisp-server
  (if (peer-available-p :python)
      (ok (catalog-ok-p (foreign-client-talk :python (lisp-server-command))))
      (skip "python peer not available")))
