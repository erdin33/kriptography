require 'minitest/autorun'
require 'rack/test'
require 'json'

require_relative '../../../app'

class Bug005CrlfNormalizationTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def test_crlf_normalization_due_to_form_data
    # I12 Integritas UI: UI tidak mengubah data secara diam-diam.
    
    # Pada browser, FormData.append('text', "A\nB") dikirim sebagai "A\r\nB".
    # Kita simulasikan payload yang diterima API:
    post '/api/encrypt', {
      cipher: 'extended_vigenere',
      params: { 'key' => 'K' }.to_json,
      input_type: 'text',
      text: "A\r\nB"
    }
    
    assert_equal 200, last_response.status
    res = JSON.parse(last_response.body)
    
    # API membalas dengan base64 payload terenkripsi, kita cek plain_bytes yang dihitung API
    # res['input']['plain_base64'] adalah base64 dari text asli.
    plain_b64 = res['input']['plain_base64']
    plain_text = plain_b64.unpack1('m0')
    
    # Test will fail if API doesn't sanitize \r\n to \n
    assert_equal "A\nB", plain_text, "Melanggar I12: Teks dengan baris baru bermutasi menjadi CRLF dan tidak dibersihkan oleh API"
  end
end
