(in-package #:mcp-parity)

(defun make-parity-server (&key (name "mcp-parity-lisp") (version "0.1.0"))
  (let ((server (make-instance 'mcp-protocol:mcp-server
                               :name name :version version
                               :instructions "stdio dual-era parity fixture")))
    (mcp-protocol:register-tool
     server
     (mcp-protocol:make-mcp-tool
      "echo" :description "echo msg"
      :input-schema (mcp-protocol:json-object "type" "object"
                                              "properties" (mcp-protocol:json-object
                                                            "msg" (mcp-protocol:json-object
                                                                   "type" "string"))
                                              "required" #("msg"))
      :handler (lambda (args)
                 (mcp-protocol:tool-result
                  (list (mcp-protocol:make-text-content
                         (or (mcp-protocol:param args "msg") "")))))))
    (mcp-protocol:register-resource
     server
     (mcp-protocol:make-mcp-resource
      "memo://hi" :name "hi" :description "hello memo"
      :handler (lambda (res)
                 (declare (ignore res))
                 "hello")))
    (mcp-protocol:register-prompt
     server
     (mcp-protocol:make-mcp-prompt
      "greet" :description "say hi"
      :handler (lambda (args)
                 (declare (ignore args))
                 (mcp-protocol:json-object
                  "messages"
                  (vector (mcp-protocol:json-object
                           "role" "user"
                           "content" (mcp-protocol:make-text-content "say hi")))))))
    server))

(defun %first-elt (seq)
  (cond
    ((and (vectorp seq) (plusp (length seq))) (aref seq 0))
    ((consp seq) (first seq))))

(defun tool-text (result)
  (let* ((content (mcp-protocol:param result "content"))
         (first (%first-elt content)))
    (mcp-protocol:param first "text")))

(defun prompt-text (prompt)
  (let* ((messages (mcp-protocol:param prompt "messages"))
         (first (%first-elt messages))
         (content (mcp-protocol:param first "content")))
    (or (mcp-protocol:param content "text")
        (and (stringp prompt) prompt)
        "")))

(defun catalog-ok-p (report)
  (let ((tools (getf report :tools))
        (echo (getf report :echo))
        (body (getf report :resource))
        (prompt (getf report :prompt)))
    (and (find "echo" tools :test #'equal)
         (equal echo "pong")
         (search "hello" (or body ""))
         (search "say hi" (or prompt "")))))
