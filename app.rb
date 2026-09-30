require 'sinatra/base'
require 'json'
require_relative 'lib/cipher_workbench'

class App < Sinatra::Base
  set :bind, '127.0.0.1'
  set :port, ENV.fetch('PORT', 4567)
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
  set :views, File.join(File.dirname(__FILE__), 'views')

  get '/health' do
    content_type :json
    { status: 'ok', version: CipherWorkbench::VERSION }.to_json
  end

  get '/' do
    erb :index
  end
end
