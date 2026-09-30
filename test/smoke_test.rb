require_relative 'test_helper'

class SmokeTest < Minitest::Test
  include RackTestHelper

  def test_health_check
    get '/health'
    assert_predicate last_response, :ok?
    assert_equal 'application/json', last_response.content_type
    
    payload = JSON.parse(last_response.body)
    assert_equal 'ok', payload['status']
  end

  def test_index
    get '/'
    assert_predicate last_response, :ok?
  end
end
