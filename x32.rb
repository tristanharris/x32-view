require 'rubygems'
require 'osc-ruby'
require 'osc-ruby/em_server'

class X32
  attr_reader :channels, :connection

  class Channel
    attr_reader :id, :grp
    attr :name, true
    attr :mute, true

    def initialize(grp, id, name)
      @grp, @id, @name = grp, id, name
    end

    def idx
      @grp == 'ch' ? id : id + 32
    end

  end

  class Connection < OSC::Server

    def initialize(ip, port)
      @socket = UDPSocket.new
      @socket.connect(ip, port)
      @matchers = []
      @queue = Queue.new
    end

    def cmd(*args)
      msg = OSC::Message.new(*args)
      @socket.send msg.encode, 0
    end

  end

  def initialize(ip, port)
    @channels = (1..32).map {|ch| Channel.new('ch', ch, '')}
    @channels += (1..8).map {|ch| Channel.new('auxin', ch, '')}
    @connection = Connection.new(ip, port)
    @connection.add_method(Regexp.new('/ch/[0-9][0-9]/config/name')) do | message |
      ch = Regexp.new('/ch/([0-9][0-9])/config/name').match(message.address)[1]
      update_channel(ch.to_i, :name, message.to_a[0])
    end
    @connection.add_method(Regexp.new('/auxin/[0-9][0-9]/config/name')) do | message |
      ch = Regexp.new('/auxin/([0-9][0-9])/config/name').match(message.address)[1]
      update_channel(ch.to_i + 32, :name, message.to_a[0])
    end
    @connection.add_method(Regexp.new('/ch/[0-9][0-9]/mix/on')) do | message |
      ch = Regexp.new('/ch/([0-9][0-9])/mix/on').match(message.address)[1]
      update_channel(ch.to_i, :mute, message.to_a[0] === 0)
    end
    @connection.add_method(Regexp.new('/auxin/[0-9][0-9]/mix/on')) do | message |
      ch = Regexp.new('/auxin/([0-9][0-9])/mix/on').match(message.address)[1]
      update_channel(ch.to_i + 32, :mute, message.to_a[0] === 0)
    end
  end

  def run
    Thread.new do
      @connection.run
    end
    @channels.each do |ch|
      @connection.cmd "/#{ch.grp}/%02d/config/name" % ch.id
      @connection.cmd "/#{ch.grp}/%02d/mix/on" % ch.id
    end
  end

  private
  def update_channel(id, field, value)
    @channels[id - 1].send(field.to_s+'=', value)
  end

end
%q{
x32 = X32.new('127.0.0.1', 10023)
x32.run
#x32.cmd "/shutdown"
sleep 5
}
%q{
#@client = OSC::Client.new( '10.0.3.243', 10023 )
@client = OSC::Client.new( '127.0.0.1', 10023 )

def @client.sock
  @so
end

@client.send( OSC::Message.new( "/shutdown" ))
p @client.sock.recvfrom(1000)
@client.send( OSC::Message.new( "/ch/01/config/name" ))
p @client.sock.recvfrom(1000)

@client.send( OSC::Message.new( "/meters", "meters/13", 16 ))
#p @client.sock.recvfrom_nonblock(1000)
loop do
  blob = @client.sock.recvfrom(1000)[0]
  p blob.unpack('g'*48)
end
#sleep 3
#}
