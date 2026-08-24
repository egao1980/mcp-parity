(in-package #:mcp-parity/tests)

(deftest lisp-client-lisp-server
  (ok (catalog-ok-p (lisp-inprocess-talk))))

(deftest lisp-client-node-server
  (if (peer-available-p :node)
      (ok (catalog-ok-p (lisp-stdio-talk (peer-server-command :node))))
      (skip "node peer not available")))

(deftest lisp-client-python-server
  (if (peer-available-p :python)
      (ok (catalog-ok-p (lisp-stdio-talk (peer-server-command :python))))
      (skip "python peer not available")))

(deftest lisp-client-lisp-http-server
  (ok (catalog-ok-p (lisp-http-lisp-server))))

(deftest lisp-client-node-http-server
  (if (http-peer-available-p :node)
      (ok (catalog-ok-p (lisp-http-peer-server :node)))
      (skip "node HTTP peer not available")))

(deftest lisp-client-python-http-server
  (if (http-peer-available-p :python)
      (ok (catalog-ok-p (lisp-http-peer-server :python)))
      (skip "python HTTP peer not available")))
