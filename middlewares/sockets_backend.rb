require 'faye/websocket'
require 'thread'
require 'json'
require 'erb'

require 'osc-ruby'
require 'osc-ruby/em_server'

module X32Watch
  class SocketsBackend
    KEEPALIVE_TIME = 15 # in seconds

    def initialize(app)
      @app     = app
      @clients = []

      Thread.new do
        loop do
          Desk.connection.cmd( "/meters", "/meters/13", 40)
          sleep 9
        end
      end

      Desk.connection.add_method('/meters/13') do | message |
        data = message.to_a[0]
        data = data.unpack('V'+('e'*48))
        len = data.shift
        data = data.map{|v| v || 0}
        @clients.each {|ws| ws.send(data.to_json)}
      end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id, env['REMOTE_ADDR']]
          @clients << ws
        end

        ws.on :message do |event|
          p [:message, event.data]
        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
      end
    end

  end
end
