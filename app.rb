require 'sinatra/base'
require_relative 'x32'

Desk = X32.new(ENV['X32_IP'], ENV['X32_PORT'])
Desk.run

module X32Watch
  class App < Sinatra::Base
    get "/" do
      @channels = Desk.channels
      erb :"index.html"
    end
  end
end
