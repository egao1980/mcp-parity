(in-package #:mcp-parity)

(defun %elicitation-params ()
  (mcp-protocol:json-object
   "message" "need a value"
   "requestedSchema"
   (mcp-protocol:json-object
    "type" "object"
    "properties" (mcp-protocol:json-object
                  "value" (mcp-protocol:json-object "type" "string"))
    "required" #("value"))))

(defun make-parity-server (&key (name "mcp-parity-lisp") (version "0.1.0"))
  (let ((server (make-instance 'mcp-protocol:mcp-server
                               :name name :version version
                               :instructions "stdio dual-era parity fixture"))
        ;; tools/call dispatch does not yet hand inputResponses to the handler.
        ;; First call returns input_required; the client's MRTR retry completes.
        (waiting t))
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
    (mcp-protocol:register-tool
     server
     (mcp-protocol:make-mcp-tool
      "need-input" :description "trigger elicitation / input_required"
      :input-schema (mcp-protocol:json-object "type" "object")
      :handler (lambda (args)
                 (declare (ignore args))
                 (if waiting
                     (progn
                       (setf waiting nil)
                       (mcp-protocol:request-elicitation (%elicitation-params)))
                     (progn
                       (setf waiting t)
                       (mcp-protocol:tool-result
                        (list (mcp-protocol:make-text-content "got-input")))))))))
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

(defun %invalid-params-p (code)
  (eql code rpc-protocol:+invalid-params+))

(defun %input-rejected-p (code)
  "Spec is -32602. FastMCP 3 currently returns a tool isError result instead."
  (or (%invalid-params-p code)
      (member code '(:tool-is-error "isError") :test #'equal)))

(defun probe-invalid-echo (client)
  "Call echo with missing `msg` and wrong-type `msg`. Return plist of RPC codes.
   Spec: inputSchema failure is JSON-RPC -32602 (invalid params)."
  (flet ((code (args)
           (handler-case
               (let ((result (mcp-protocol:call-tool client "echo" args)))
                 (if (and (hash-table-p result) (mcp-protocol:param result "isError"))
                     :tool-is-error
                     :accepted))
             (mcp-protocol:mcp-error (c)
               (mcp-protocol:mcp-error-code c)))))
    (list :missing (code (mcp-protocol:json-object))
          :wrong-type (code (mcp-protocol:json-object "msg" 1)))))

(defun input-validation-ok-p (report)
  (and (%input-rejected-p (getf report :invalid-missing))
       (%input-rejected-p (getf report :invalid-type))))

(defun %need-input-text (result)
  (or (tool-text result)
      (and (hash-table-p result) (mcp-protocol:param result "resultType"))
      ""))

(defun probe-need-input (client)
  "Call need-input. Lisp client auto-retries input_required via fulfill-input-requests."
  (handler-case
      (let ((result (mcp-protocol:call-tool client "need-input"
                                            (mcp-protocol:json-object))))
        (list :text (%need-input-text result)
              :result-type (and (hash-table-p result)
                                (mcp-protocol:param result "resultType"))))
    (mcp-protocol:mcp-error (c)
      (list :text (mcp-protocol:mcp-error-message c)
            :result-type nil))))

(defun input-required-ok-p (report)
  (let ((tools (getf report :tools))
        (text (or (getf report :need-input) ""))
        (rtype (getf report :need-input-type)))
    (and (find "need-input" tools :test #'equal)
         (search "got-input" text)
         (not (equal rtype "input_required")))))
