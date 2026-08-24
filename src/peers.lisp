(in-package #:mcp-parity)

(defparameter *peer-root*
  (asdf:system-relative-pathname "mcp-parity" "peers/")
  "Directory containing node/ and python/ peer programs.")

(defun %env-off-p (name)
  (member (uiop:getenv name) '("0" "false" "no" "off") :test #'string-equal))

(defun peers-enabled-p ()
  (not (%env-off-p "MCP_PARITY_PEERS")))

(defun which (program)
  (or (uiop:getenv (format nil "MCP_PARITY_~a" (string-upcase program)))
      (ignore-errors
        (string-trim '(#\space #\newline #\return)
                     (uiop:run-program (list "which" program)
                                       :output :string :error-output nil)))))

(defun node-available-p ()
  (and (peers-enabled-p)
       (which "node")
       (probe-file (merge-pathnames "node/server.mjs" *peer-root*))
       (probe-file (merge-pathnames "node/node_modules" *peer-root*))))

(defun python-venv ()
  (let ((root (merge-pathnames "python/" *peer-root*)))
    (find-if #'probe-file
             (list (merge-pathnames ".venv/bin/python" root)
                   (merge-pathnames ".venv/bin/python3" root)
                   (merge-pathnames ".venv/Scripts/python.exe" root)))))

(defun python-available-p ()
  (and (peers-enabled-p)
       (or (python-venv) (which "uv") (which "python3"))
       (probe-file (merge-pathnames "python/server.py" *peer-root*))))

(defun peer-available-p (kind)
  (ecase kind
    (:node (node-available-p))
    (:python (python-available-p))
    (:lisp t)))

(defun python-cmd (script &rest args)
  (let ((script-path (uiop:native-namestring
                      (merge-pathnames script (merge-pathnames "python/" *peer-root*))))
        (project (uiop:native-namestring (merge-pathnames "python/" *peer-root*))))
    (cond
      ((python-venv)
       (list* (uiop:native-namestring (python-venv)) "-u" script-path args))
      ((which "uv")
       (list* (which "uv") "run" "--no-sync"
              "--project" project
              "python" "-u" script-path args))
      ((which "python3")
       (list* (which "python3") "-u" script-path args))
      (t
       (error "no python runtime for peer ~a" script)))))

(defun peer-server-command (kind)
  (ecase kind
    (:node
     (list (which "node")
           (uiop:native-namestring (merge-pathnames "node/server.mjs" *peer-root*))))
    (:python
     (python-cmd "server.py"))))

(defun lisp-server-command ()
  (list (or (which "ros") "ros") "-Q"
        "-l" (uiop:native-namestring
              (asdf:system-relative-pathname "mcp-parity" "scripts/lisp-server.lisp"))))

(defun client-command (kind server-cmd)
  (ecase kind
    (:node
     (list* (which "node")
            (uiop:native-namestring (merge-pathnames "node/client.mjs" *peer-root*))
            server-cmd))
    (:python
     (append (python-cmd "client.py") server-cmd))))
