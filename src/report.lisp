(in-package #:mcp-parity)

(defun print-matrix ()
  (format t "~&mcp-parity matrix~%")
  (format t "  peers: node=~a python=~a~%"
          (if (node-available-p) "yes" "no")
          (if (python-available-p) "yes" "no"))
  (format t "  catalog: echo / need-input / memo://hi / greet (stdio + streamable HTTP)~%")
  (format t "  inputSchema: echo missing/wrong-type → -32602~%")
  (format t "  input_required: need-input elicitation round-trip~%")
  (format t "  gaps: sibling discover probe, OAuth, Tasks~%")
  (values))
