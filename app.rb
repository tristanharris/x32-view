require 'sinatra/base'
require_relative 'x32'

#Desk = X32.new('127.0.0.1', 10023)
Desk = X32.new('10.0.3.243', 10023)
Desk.run

module ChatDemo
  class App < Sinatra::Base
    get "/" do
      @channels = Desk.channels
      erb :"index.html"
    end

    get "/assets/js/application.js" do
      content_type :js
      @scheme = ENV['RACK_ENV'] == "production" ? "wss://" : "ws://"
      erb :"application.js"
    end
  end
end
