ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../app'

module RackTestHelper
  include Rack::Test::Methods

  def app
    App
  end
end
