require 'socket'

host = '0.0.0.0'
port = 10
s = TCPSocket.new(host, port)
text = "hello world"
bytes = text.bytes
s.write bytes.pack('c*')