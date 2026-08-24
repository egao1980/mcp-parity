(defsystem "mcp-parity"
  :version "0.1.1"
  :description "Interop canary: mcp-protocol vs FastMCP 3 / official Node MCP SDK"
  :author "egao1980"
  :license "MIT"
  :depends-on ("mcp-protocol"
               "mcp-backend-stdio"
               (:version "mcp-backend-streamable-http" "0.1.1")
               "rpc-protocol"
               "rpc-backend-inprocess"
               "process-backend-uiop"
               "http-protocol"
               "http-backend-dexador"
               "http-server-protocol"
               "http-server-backend-hunchentoot"
               "uiop"
               "usocket"
               "rove")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "catalog")
               (:file "peers")
               (:file "harness")
               (:file "http")
               (:file "report"))
  :in-order-to ((test-op (test-op "mcp-parity/tests"))))

(defsystem "mcp-parity/tests"
  :depends-on ("mcp-parity" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "lisp-client")
               (:file "foreign-client"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "mcp-parity tests failed"))))
