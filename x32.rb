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
      @grp, @id, @name = grp, id, grp+':'+id.to_s
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
    @on_update = nil
    @connection.add_method(Regexp.new('/ch/[0-9][0-9]/config/name')) do | message |
      ch = Regexp.new('/ch/([0-9][0-9])/config/name').match(message.address)[1]
      update_channel(ch.to_i, :name, message.to_a[0])
    end
    @connection.add_method(Regexp.new('/auxin/[0-9][0-9]/config/name')) do | message |
      ch = Regexp.new('/auxin/([0-9][0-9])/config/name').match(message.address)[1]
      update_channel(ch.to_i + 32, :name, message.to_a[0])
    end
    @connection.add_method('/chmute') do | message |
      data = message.to_a[0].unpack('V'+('V'*32))
      data.shift
      data.each_with_index do |state, idx|
        update_channel(idx + 1, :mute, state === 0)
      end
    end
    @connection.add_method('/auxmute') do | message |
      data = message.to_a[0].unpack('V'+('V'*8))
      data.shift
      data.each_with_index do |state, idx|
        update_channel(idx + 1 + 32, :mute, state === 0)
      end
    end
  end

  def poll_channels(speed = 80)
    @connection.cmd('/formatsubscribe', '/chmute', '/ch/**/mix/on', 1, 32, speed)
    @connection.cmd('/formatsubscribe', '/auxmute', '/auxin/**/mix/on', 1, 8, speed)
  end

  def run
    Thread.new do
      @connection.run
    end
    @channels.each do |ch|
      @connection.cmd "/#{ch.grp}/%02d/config/name" % ch.id
    end
    Thread.new do
      loop do
        @connection.cmd '/renew'
        sleep 8
      end
    end
  end

  def on_update(&block)
    @on_update = block
  end

  private
  def update_channel(id, field, value)
    ch = @channels[id - 1]
    if ch.send(field) != value
      ch.send(field.to_s+'=', value)
      @on_update.call(ch) if @on_update
    end
  end

end
