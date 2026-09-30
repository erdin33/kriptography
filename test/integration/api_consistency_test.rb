require_relative '../test_helper'
require_relative '../../scripts/sample_keys'
require_relative '../../app'
require 'rack/test'

class ApiConsistencyTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def test_api_vs_service
    keys = SampleKeys.keys['vigenere']
    text = "HELLO API"

    # API Request
    post '/api/encrypt', {
      cipher: 'vigenere',
      params: keys.to_json,
      input_type: 'text',
      text: text
    }
    
    assert last_response.ok?
    api_res = JSON.parse(last_response.body)

    # Service Request
    srv_res = CipherWorkbench::Service.encrypt(
      cipher_id: 'vigenere',
      params: keys,
      input: { kind: :text, text: text }
    )

    b64 = [srv_res.payload].pack('m0')
    assert_equal b64, api_res['output']['base64']
  end
end
