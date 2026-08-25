(defpackage #:mcp-parity/tests
  (:use #:cl #:rove #:mcp-parity))

(in-package #:mcp-parity/tests)

(defun %catalog+schema (report)
  (ok (catalog-ok-p report))
  (ok (input-validation-ok-p report)))
