require './app'
require './middlewares/sockets_backend'

THRESHOLD = 0.001

use X32Watch::SocketsBackend

run X32Watch::App
