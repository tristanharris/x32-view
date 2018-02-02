require 'faye/websocket'
require 'thread'
require 'json'
require 'erb'

require 'osc-ruby'
require 'osc-ruby/em_server'

module ChatDemo
  class ChatBackend
    KEEPALIVE_TIME = 15 # in seconds

    def initialize(app)
      @app     = app
      @clients = []
      @oscclient = OSC::Client.new( '10.0.3.243', 10023 )
      #@oscclient = OSC::Client.new( 'localhost', 8888 )

      def @oscclient.sock
        @so
      end

      Thread.new do
        loop do
          #@oscclient.send( OSC::Message.new( "/meters", "meters/13", 16 )) unless @clients.empty?
          Desk.connection.cmd( "/meters", "/meters/13", 40)
          sleep 9
        end
      end

    Desk.connection.add_method('/meters/13') do | message |
          #data = message[0].to_a[0]
          #@clients.each {|ws| ws.send(data.unpack('g'*32).to_json)}
          data = message.to_a[0]
    p data
    data=data.unpack('V'+('e'*48))
    p data
    len = data.shift
          data=data.map{|v| v || 0}
          @clients.each {|ws| ws.send(data.to_json)}
    end
      #p OSC::Message.new('/foo', OSC::OSCBlob.new((101..132).to_a.pack('g'*32))).encode.inspect
  %q{
      Thread.new do
        loop do
          p 'rec1'
          blob = @oscclient.sock.recvfrom(1000)
          osc = OSC::OSCPacket.messages_from_network(blob[0], blob[1])
          #p osc
          data = osc[0].to_a[0]
          @clients.each {|ws| ws.send(data.unpack('g'*32).to_json)}
        end
      end
  }
    end

    def msg(data)
      @clients.each {|ws| ws.send(data)}
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
