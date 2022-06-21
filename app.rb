require 'sinatra/base'
require_relative 'x32'

Config = {
  meter_refresh: 40,
  channel_refresh: 80,
  desk_ip: ENV['X32_IP']
}

Thread::abort_on_exception = true

class Restarter

  def initialize(null_object = nil, &block)
    @handle = nil
    @init = block
    @on_start = []
    @null_object = null_object
  end

  def reconnect
    if running?
      @handle.stop
      @handle = nil
    end
    run
  end

  def running?
    @handle != nil
  end

  def run
    return if running?
    h = @init.call
    return unless h
    @handle = h
    @on_start.each do |p|
      p.call(@handle)
    end
  end

  def on_start(&block)
    @on_start << block
    block.call(@handle) if running?
  end

  def get
    @handle || @null_object
  end

end

Desk = Restarter.new(OpenStruct.new(channels: [])) do
  begin
    X32.new(Config[:desk_ip], ENV['X32_PORT']).tap{|d| d.run}
  rescue Errno::ECONNREFUSED => e
    false
  end
end

Desk.on_start do |d|
  d.poll do |x|
    x.poll_channels(Config[:channel_refresh])
    x.connection.cmd( "/meters", "/meters/13", Config[:meter_reshresh])
  end
end

begin
  Desk.run
rescue => e
  puts "Failed to connect to desk on #{ENV['X32_IP']}:#{ENV['X32_PORT']}"
  puts e
  exit 1
end

module X32Watch
  class App < Sinatra::Base

    set :haml, :format => :html5

    get "/" do
      @channels = Desk.get.channels
      haml :index
    end

    get "/config" do
      haml :config, :locals => {config: Config}
    end

    post "/config" do
      cfg = params[:cfg]
      Config.each_pair do |k, v|
        if cfg[k] && Config[k].to_s != cfg[k]
          Config[k] = cfg[k]
          case k
            when :channel_refresh
              Desk.get.poll_channels(Config[:channel_refresh])
            when :meter_refresh
              Desk.get.connection.cmd( "/meters", "/meters/13", Config[:meter_reshresh])
            when :desk_ip
              Desk.reconnect
          end
        end
      end
      redirect '/config'
    end

  end
end
