require 'sinatra/base'
require_relative 'x32'

Desk = X32.new('127.0.0.1', 10023)
#Desk = X32.new('10.0.3.243', 10023)
Desk.run

module X32Watch
  class App < Sinatra::Base
    get "/" do
      @channels = Desk.channels
      erb :"index.html"
    end
  end
end
