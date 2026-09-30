require 'sinatra/base'
require 'json'
require_relative 'lib/cipher_workbench'
require_relative 'lib/cipher_workbench/api'

class App < Sinatra::Base
  set :bind, '127.0.0.1'
  set :port, ENV.fetch('PORT', 4567)
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
  set :views, File.join(File.dirname(__FILE__), 'views')

  use CipherWorkbench::Api

  get '/health' do
    content_type :json
    { status: 'ok', version: CipherWorkbench::VERSION }.to_json
  end

  get '/' do
    erb :index
  end

  get '/dev/gallery' do
    if ENV['RACK_ENV'] == 'production'
      halt 404, "Not Found"
    else
      send_file File.join(settings.public_folder, 'dev', 'gallery.html')
    end
  end
end
