require 'faye/websocket'
require 'thread'
require 'json'

require 'osc-ruby'
require 'osc-ruby/em_server'

module X32Watch
  class SocketsBackend
    KEEPALIVE_TIME = 15 # in seconds

    def initialize(app)
      @app     = app
      @clients = []
      @last_time_signal_ok = [Time.now]*48
      @last_update = Time.now

      Desk.on_start do |d|
        d.connection.add_method('/meters/13') do | message |
          if Time.now - @last_update > 1
            @last_update = Time.now
          data = message.to_a[0]
          data = data.unpack('V'+('e'*48))
          len = data.shift
          data = data.map{|v| v || 0}
     # data = data.map{rand}
        #  msg :meters, data
          data.each_with_index do |v, i|
            @last_time_signal_ok[i] = Time.now if v > THRESHOLD
          end
          msg :signal, @last_time_signal_ok.map{|t| Time.now-t}
          end
        end

        d.on_update do |channel|
          msg(:channel, {:idx => channel.idx, :name => channel.name, :mute => channel.mute})
        end
        d.on_connection_lost do
          msg :connection_lost, nil
        end
      end

    end

    def msg(type, data)
      @clients.each {|ws| ws.send({type: type, data: data}.to_json)}
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {})
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
