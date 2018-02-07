require 'sinatra/base'
require_relative 'x32'

Desk = X32.new(ENV['X32_IP'], ENV['X32_PORT'])
Desk.run

module X32Watch
  class App < Sinatra::Base

    set :haml, :format => :html5

    get "/" do
      @channels = Desk.channels
      haml :index
    end

  end
end
