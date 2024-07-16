apiVersion: v1
data:
  proxy.py: |-
    import http.server
    import socketserver
    import urllib.request
    import signal
    import sys

    def signal_handler(sig, frame):
        print('SIGTERM received....exit now')
        sys.exit(0)

    class MyProxy(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            forbidden = ('/api/v1/query', '/api/v1/series', '/api/v1/format_query',
                         '/api/v1/label', '/api/v1/admin', '/api/v1/write',
                         '/api/v2/', '/status', '/rules', '/metrics', '/federate',
                         '/alerts', '/graph', '/classic')

            if self.path.startswith(forbidden) or self.path == '/':
                self.send_response(302)
                self.send_header('Location', "/targets")
                self.end_headers()
                return

            upstream = "http://127.0.0.1:9090" + self.path
            self.send_response(200)
            self.end_headers()
            self.copyfile(urllib.request.urlopen(upstream), self.wfile)

    PORT = 8085
    httpd = None
    # catch kubernetes pod termination signal (SIGTERM - 15)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        socketserver.TCPServer.allow_reuse_address = True
        httpd = socketserver.TCPServer(('', PORT), MyProxy)
        print(f"Proxy at: http://localhost:{PORT}")
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("Pressed Ctrl+C")
    finally:
        if httpd:
            httpd.shutdown()
kind: ConfigMap
metadata:
  name: proxy-script
  namespace: ichp-user-workload-monitoring
