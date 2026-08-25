(in-package #:mcp-parity)

(defun %ensure-process-backend ()
  (or process-protocol:*process-backend*
      (progn
        (asdf:load-system "process-backend-uiop")
        (process-backend-uiop:use-uiop-process-backend))))

(defun %report (client)
  (let* ((tools (mcp-protocol:list-tools client))
         (call (mcp-protocol:call-tool client "echo"
                                       (mcp-protocol:json-object "msg" "pong")))
         (res (mcp-protocol:read-resource client "memo://hi"))
         (prompt (mcp-protocol:get-prompt client "greet"))
         (invalid (probe-invalid-echo client)))
    (list :era (mcp-protocol:mcp-client-era client)
          :tools (mapcar #'mcp-protocol:mcp-tool-name tools)
          :echo (tool-text call)
          :resource (let* ((contents (mcp-protocol:param res "contents"))
                           (first (and (vectorp contents) (plusp (length contents))
                                       (aref contents 0))))
                      (or (mcp-protocol:param first "text") ""))
          :prompt (prompt-text prompt)
          :invalid-missing (getf invalid :missing)
          :invalid-type (getf invalid :wrong-type))))

(defun lisp-inprocess-talk ()
  (let* ((server (make-parity-server))
         (transport (rpc-backend-inprocess:make-inprocess-rpc-transport))
         (client (make-instance 'mcp-protocol:mcp-client
                                :transport transport
                                :era :unknown
                                :name "mcp-parity-lisp"
                                :version "0.1.0")))
    (mcp-protocol:serve-mcp server :transport transport)
    (mcp-protocol:mcp-initialize client)
    (%report client)))

(defun lisp-stdio-talk (command)
  (%ensure-process-backend)
  (mcp-backend-stdio:use-stdio-mcp-backend)
  (let ((client (mcp-protocol:mcp-connect :command command :probe t
                                          :name "mcp-parity-lisp"
                                          :version "0.1.0")))
    (%report client)))

(defun parse-json-line (line)
  (when (and line (plusp (length (string-trim '(#\space) line))))
    (ignore-errors (rpc-protocol:decode-message line))))

(defun %js-string (obj key)
  (let ((v (and obj (gethash key obj))))
    (cond
      ((null v) "")
      ((stringp v) v)
      (t (princ-to-string v)))))

(defun %js-tools (obj)
  (let ((raw (and obj (gethash "tools" obj))))
    (cond
      ((null raw) nil)
      ((vectorp raw) (map 'list #'identity raw))
      ((listp raw) raw)
      (t (list raw)))))

(defun %js-code (obj key)
  (let ((v (and obj (gethash key obj))))
    (cond
      ((integerp v) v)
      ((or (equal v "isError") (eq v :tool-is-error)) :tool-is-error)
      ((and (stringp v) (plusp (length v)))
       (or (ignore-errors (parse-integer v :junk-allowed t)) v))
      ((eq v t) :accepted)
      ((eq v :null) nil)
      (t v))))

(defun %foreign-report (rec)
  (list :era (gethash "era" rec)
        :tools (%js-tools rec)
        :echo (%js-string rec "echo")
        :resource (%js-string rec "resource")
        :prompt (%js-string rec "prompt")
        :invalid-missing (%js-code rec "invalidMissing")
        :invalid-type (%js-code rec "invalidType")))

(defun %run-foreign-client (kind cmd)
  (multiple-value-bind (out err)
      (uiop:run-program cmd
                        :output :string
                        :error-output :string
                        :ignore-error-status t)
    (let ((parsed (loop for line in (uiop:split-string out :separator '(#\newline))
                        for rec = (parse-json-line line)
                        when rec collect rec)))
      (unless parsed
        (error "foreign client ~a produced no JSON~%cmd: ~s~%stdout:~%~a~%stderr:~%~a"
               kind cmd out err))
      (%foreign-report (first (last parsed))))))

(defun foreign-client-talk (kind server-cmd)
  (%run-foreign-client kind (client-command kind server-cmd)))
