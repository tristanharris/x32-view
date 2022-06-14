require 'sinatra/base'
require_relative 'x32'

begin
  Desk = X32.new(ENV['X32_IP'], ENV['X32_PORT'])
  Desk.run
rescue => e
  puts "Failed to connect to desk on #{ENV['X32_IP']}:#{ENV['X32_PORT']}"
  puts e
  exit 1
end

module X32Watch
  class App < Sinatra::Base
    get "/" do
      @channels = Desk.channels
      erb :"index.html"
    end
  end
end
