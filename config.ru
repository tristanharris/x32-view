require './app'
require './middlewares/sockets_backend'

use X32Watch::SocketsBackend

run X32Watch::App
