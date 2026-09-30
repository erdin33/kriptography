require_relative '../test_helper'
require 'rack/test'
require 'stringio'

class ApiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def test_get_ciphers
    get '/api/ciphers'
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert data['ok']
    
    ids = data['ciphers'].map { |c| c['id'] }
    assert_equal %w[vigenere autokey extended_vigenere playfair affine hill super enigma].sort, ids.sort
    refute_includes ids, 'columnar'
  end

  def test_vigenere_text_encryption
    post '/api/encrypt', {
      cipher: 'vigenere',
      params: { key: 'LEMON' }.to_json,
      input_type: 'text',
      text: 'ATTACKATDAWN'
    }
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert_equal 'lxfopvefrnhr', data['output']['letters']
    assert_equal 'pesan-vigenere.dat', data['suggested_filename']
    assert_equal ["LXFOPVEFRNHR".bytes.to_a.pack('C*')].pack('m0'), data['output']['base64']
    
    # Upper
    post '/api/encrypt', {
      cipher: 'vigenere',
      params: { key: 'LEMON' }.to_json,
      input_type: 'text',
      text: 'ATTACKATDAWN',
      display_case: 'upper'
    }
    data_up = JSON.parse(last_response.body)
    assert_equal 'LXFOPVEFRNHR', data_up['output']['letters']
  end

  def test_roundtrip_all_ciphers_and_text_decrypt
    ciphers_keys = [
      ['vigenere', { key: 'TEST' }],
      ['autokey', { key: 'TEST' }],
      ['playfair', { key: 'TEST' }],
      ['affine', { a: 3, b: 5 }],
      ['hill', { n: 2, matrix: [[3,3],[2,5]] }],
      ['enigma', { rotors: 'I,II,III', reflector: 'B', rings: 'AAA', positions: 'AAA' }]
    ]
    
    ciphers_keys.each do |c_id, key_params|
      # ENCRYPT
      post '/api/encrypt', {
        cipher: c_id,
        params: key_params.to_json,
        input_type: 'text',
        text: 'HELO'
      }
      assert_equal 200, last_response.status, "Failed encrypt #{c_id}: #{last_response.body}"
      enc_data = JSON.parse(last_response.body)
      
      ct_letters = enc_data['output']['letters']
      container = enc_data['container_b64'].unpack1('m0')
      
      # DECRYPT CONTAINER
      file = Rack::Test::UploadedFile.new(StringIO.new(container), 'application/octet-stream', original_filename: 'x.dat')
      post '/api/decrypt', {
        cipher: c_id,
        params: key_params.to_json,
        source: 'container',
        file: file
      }
      assert_equal 200, last_response.status, "Failed decrypt container #{c_id}: #{last_response.body}"
      dec_data = JSON.parse(last_response.body)
      assert_equal 'HELO', dec_data['text']
      
      # DECRYPT TEXT (LETTERS)
      post '/api/decrypt', {
        cipher: c_id,
        params: key_params.to_json,
        source: 'text',
        text: ct_letters,
        text_format: 'letters'
      }
      assert_equal 200, last_response.status, "Failed decrypt text #{c_id}: #{last_response.body}"
      dec_txt_data = JSON.parse(last_response.body)
      assert_equal 'HELO', dec_txt_data['text']
    end
  end

  def test_roundtrip_file_and_mime_guess
    c_id = 'extended_vigenere'
    key_params = { key: 'KEY' }
    
    bytes = "test file data".b
    file = Rack::Test::UploadedFile.new(StringIO.new(bytes), 'image/jpeg', original_filename: 'photo.jpg')
    
    post '/api/encrypt', {
      cipher: c_id,
      params: key_params.to_json,
      input_type: 'file',
      file: file
    }
    assert_equal 200, last_response.status
    enc_data = JSON.parse(last_response.body)
    assert_nil enc_data['output']['letters']
    assert_equal 'photo.jpg.dat', enc_data['suggested_filename']
    
    container = enc_data['container_b64'].unpack1('m0')
    
    # Decrypt
    c_file = Rack::Test::UploadedFile.new(StringIO.new(container), 'application/octet-stream', original_filename: 'photo.jpg.dat')
    post '/api/decrypt', {
      cipher: c_id,
      params: key_params.to_json,
      source: 'container',
      file: c_file
    }
    assert_equal 200, last_response.status, "Failed roundtrip file: #{last_response.body}"
    dec_data = JSON.parse(last_response.body)
    
    assert_equal 'photo.jpg', dec_data['filename']
    assert_equal 'image/jpeg', dec_data['mime_guess']
    assert_equal true, dec_data['integrity']['valid']
    assert_equal [bytes].pack('m0'), dec_data['plain_full_b64']
  end

  def test_inspect_endpoint
    bytes = "data".b
    file = Rack::Test::UploadedFile.new(StringIO.new(bytes), 'text/plain', original_filename: 'x.txt')
    post '/api/encrypt', {
      cipher: 'vigenere',
      params: { key: 'A' }.to_json,
      input_type: 'file',
      file: file
    }
    assert_equal 200, last_response.status, "Inspect setup encrypt failed: #{last_response.body}"
    container = JSON.parse(last_response.body)['container_b64'].unpack1('m0')
    
    c_file = Rack::Test::UploadedFile.new(StringIO.new(container), 'application/octet-stream', original_filename: 'x.dat')
    post '/api/inspect', { file: c_file }
    assert_equal 200, last_response.status, "Inspect failed: #{last_response.body}"
    insp = JSON.parse(last_response.body)
    assert_equal 'vigenere', insp['cipher']
    assert_equal 'x.txt', insp['filename']
  end

  def test_wrong_key_integrity_and_mismatch
    bytes = "A" * 50
    file = Rack::Test::UploadedFile.new(StringIO.new(bytes), 'text/plain', original_filename: 'x.txt')
    post '/api/encrypt', {
      cipher: 'extended_vigenere',
      params: { key: 'A' }.to_json,
      input_type: 'file',
      file: file
    }
    container = JSON.parse(last_response.body)['container_b64'].unpack1('m0')
    
    # Wrong key for ext vig (byte domain -> invalid integrity but no error)
    c_file = Rack::Test::UploadedFile.new(StringIO.new(container), 'application/octet-stream', original_filename: 'x.dat')
    post '/api/decrypt', {
      cipher: 'extended_vigenere',
      params: { key: 'B' }.to_json,
      source: 'container',
      file: c_file
    }
    assert_equal 200, last_response.status
    dec = JSON.parse(last_response.body)
    assert_equal false, dec['integrity']['valid']
    
    # Cipher mismatch
    c_file.rewind
    post '/api/decrypt', {
      cipher: 'super',
      params: { vigenere_key: 'A', transposition_key: 'AB' }.to_json,
      source: 'container',
      file: c_file
    }
    assert_equal 409, last_response.status
    assert_equal 'cipher_mismatch', JSON.parse(last_response.body)['error']
  end

  def test_error_status_codes
    # 400 invalid input
    post '/api/encrypt', { cipher: 'vigenere' }
    assert_equal 400, last_response.status
    
    # 400 invalid params JSON
    post '/api/encrypt', { cipher: 'vigenere', params: '{', input_type: 'text' }
    assert_equal 400, last_response.status
    
    # 422 invalid key
    post '/api/encrypt', { cipher: 'vigenere', params: { key: '' }.to_json, input_type: 'text', text: 'A' }
    assert_equal 422, last_response.status
    
    # 400 invalid container
    c_file = Rack::Test::UploadedFile.new(StringIO.new("bad data"), 'application/octet-stream', original_filename: 'x.dat')
    post '/api/decrypt', { cipher: 'vigenere', params: { key: 'A' }.to_json, source: 'container', file: c_file }
    assert_equal 400, last_response.status
  end

  def test_security_headers
    get '/api/ciphers'
    assert_equal 'nosniff', last_response.headers['X-Content-Type-Options']
    assert_equal 'no-referrer', last_response.headers['Referrer-Policy']
    assert_equal 'no-store', last_response.headers['Cache-Control']
    assert_match(/default-src 'self'/, last_response.headers['Content-Security-Policy'])
  end

  def test_payload_limit
    old_max = ENV['MAX_UPLOAD_MB']
    ENV['MAX_UPLOAD_MB'] = '0' # force very small limit by redefining it?
    # Actually, MAX_UPLOAD_BYTES is a constant, so we can't easily change it here.
    # Instead, we will simulate a large payload in test, but 25MB is too big to allocate easily.
    # Let's mock request.content_length for one request to test 413.
    # We can do this by passing CONTENT_LENGTH env.
    post '/api/encrypt', { cipher: 'vigenere' }, { 'CONTENT_LENGTH' => (26 * 1024 * 1024).to_s }
    assert_equal 413, last_response.status
    assert_equal 'payload_too_large', JSON.parse(last_response.body)['error']
    ENV['MAX_UPLOAD_MB'] = old_max
  end

  def test_logging_leakage
    # Save original streams
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    
    begin
      post '/api/encrypt', {
        cipher: 'vigenere',
        params: { key: 'SECRETKEY' }.to_json,
        input_type: 'text',
        text: 'RAHASIA-XYZ-123'
      }
      
      output = $stdout.string + $stderr.string
      refute_match(/SECRETKEY/, output)
      refute_match(/RAHASIA-XYZ-123/, output)
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end

  def test_truncated_output
    # Generate large text to exceed display limit (64KiB)
    txt = "A" * 70_000
    post '/api/encrypt', {
      cipher: 'vigenere',
      params: { key: 'A' }.to_json,
      input_type: 'text',
      text: txt
    }
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    
    assert_equal true, data['output']['base64_truncated']
    assert_equal true, data['output']['hex_truncated']
    assert data['output']['base64'].unpack1('m0').bytesize < 70_000
    
    container_bytes = data['container_b64'].unpack1('m0')
    assert container_bytes.bytesize > 70_000
  end
end
