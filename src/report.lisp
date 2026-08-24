(in-package #:mcp-parity)

(defun print-matrix ()
  (format t "~&mcp-parity matrix~%")
  (format t "  peers: node=~a python=~a~%"
          (if (node-available-p) "yes" "no")
          (if (python-available-p) "yes" "no"))
  (format t "  catalog: echo / memo://hi / greet (stdio)~%")
  (format t "  gaps: streamable HTTP, sibling discover probe, input_required~%")
  (values))
