module CipherWorkbench
  class Api < Sinatra::Base
    # Configuration
    MAX_UPLOAD_MB = ENV.fetch('MAX_UPLOAD_MB', 25).to_i
    MAX_UPLOAD_BYTES = MAX_UPLOAD_MB * 1024 * 1024
    DISPLAY_LIMIT_BYTES = 65_536

    MIME_TYPES = {
      '.jpg' => 'image/jpeg', '.jpeg' => 'image/jpeg', '.png' => 'image/png',
      '.gif' => 'image/gif', '.webp' => 'image/webp', '.pdf' => 'application/pdf',
      '.docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      '.pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      '.txt' => 'text/plain', '.csv' => 'text/csv', '.json' => 'application/json',
      '.zip' => 'application/zip', '.mp3' => 'audio/mpeg', '.wav' => 'audio/wav',
      '.mp4' => 'video/mp4', '.webm' => 'video/webm', '.sqlite' => 'application/vnd.sqlite3',
      '.db' => 'application/vnd.sqlite3', '.sql' => 'application/sql'
    }.freeze

    configure do
      set :logging, false
      set :show_exceptions, false
      set :dump_errors, false
    end

    before '/api/*' do
      headers 'X-Content-Type-Options' => 'nosniff',
              'Referrer-Policy' => 'no-referrer',
              'Cache-Control' => 'no-store',
              'Content-Security-Policy' => "default-src 'self'; img-src 'self' blob: data:; media-src 'self' blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"
              
      content_type :json
      
      request.body.rewind if request.body.respond_to?(:rewind)
      if request.content_length.to_i > MAX_UPLOAD_BYTES
        halt 413, JSON.generate({ ok: false, error: 'payload_too_large', message: 'Payload melebihi batas ukuran yang diizinkan' })
      end
    end

    error CipherWorkbench::InvalidKeyError do
      e = env['sinatra.error']
      halt 422, JSON.generate({ ok: false, error: 'invalid_key', field: e.field, message: e.message })
    end
    
    error CipherWorkbench::InvalidParamsError do
      e = env['sinatra.error']
      halt 422, JSON.generate({ ok: false, error: 'invalid_params', field: e.field, message: e.message })
    end
    
    error CipherWorkbench::InvalidInputError do
      e = env['sinatra.error']
      halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: e.field, message: e.message })
    end
    
    error CipherWorkbench::InvalidContainerError do
      e = env['sinatra.error']
      halt 400, JSON.generate({ ok: false, error: 'invalid_container', field: e.field, message: e.message })
    end
    
    error CipherWorkbench::InvalidCiphertextError do
      e = env['sinatra.error']
      halt 422, JSON.generate({ ok: false, error: 'invalid_ciphertext', field: e.field, message: e.message })
    end
    
    error CipherWorkbench::CipherMismatchError do
      e = env['sinatra.error']
      halt 409, JSON.generate({ ok: false, error: 'cipher_mismatch', field: e.field, message: e.message })
    end
    
    error StandardError do
      e = env['sinatra.error']
      halt 500, JSON.generate({ ok: false, error: 'internal_error', message: e.message, trace: e.backtrace[0..2] })
    end

    get '/api/ciphers' do
      ciphers = Registry.catalog.reject { |c| c[:group] == :internal || c[:hidden] }
      JSON.generate({
        ok: true,
        ciphers: ciphers,
        limits: {
          max_upload_bytes: MAX_UPLOAD_BYTES,
          display_limit_bytes: DISPLAY_LIMIT_BYTES
        }
      })
    end

    post '/api/encrypt' do
      cipher_id = params[:cipher] || halt(400, JSON.generate({ ok: false, error: 'invalid_input', field: 'cipher', message: 'Parameter cipher wajib diisi' }))
      
      cipher_class = Registry.all.find { |c| c.id == cipher_id }
      halt 404, JSON.generate({ ok: false, error: 'unsupported_cipher', message: 'Cipher tidak didukung' }) unless cipher_class
      
      begin
        c_params = JSON.parse(params[:params] || '{}')
      rescue JSON::ParserError
        halt 400, JSON.generate({ ok: false, error: 'invalid_params', message: 'Parameter kunci tidak valid (harus JSON)' })
      end
      
      input_type = params[:input_type]
      unless %w[text file].include?(input_type)
        halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: 'input_type', message: 'Tipe input harus text atau file' })
      end
      
      input_hash = { kind: input_type.to_sym }
      
      if input_type == 'text'
        txt = params[:text]
        txt = txt.gsub("\r\n", "\n") if txt
        halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: 'text', message: 'Teks wajib diisi' }) if txt.nil?
        if txt.bytesize > MAX_UPLOAD_BYTES
          halt 413, JSON.generate({ ok: false, error: 'payload_too_large', message: 'Teks melebihi batas ukuran' })
        end
        input_hash[:text] = txt
      else
        file_hash = params[:file]
        halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: 'file', message: 'Berkas wajib diunggah' }) unless file_hash && file_hash[:tempfile]
        input_hash[:filename] = file_hash[:filename]
        
        file_bytes = file_hash[:tempfile].read
        file_hash[:tempfile].close
        file_hash[:tempfile].unlink if file_hash[:tempfile].respond_to?(:unlink)
        
        input_hash[:bytes] = file_bytes
      end
      
      display_case = params[:display_case] == 'upper' ? :upper : :lower
      
      res = Service.encrypt(cipher_id: cipher_id, params: c_params, input: input_hash)
      
      truncated_payload, is_truncated = Codec::Views.truncate(res.payload, limit: DISPLAY_LIMIT_BYTES)
      b64 = Codec::Views.base64(truncated_payload)
      hex_val = Codec::Views.hex(truncated_payload)
      
      out_letters = res.cipher_letters
      if out_letters
        out_letters, _ = Codec::Views.truncate(out_letters, limit: DISPLAY_LIMIT_BYTES)
        out_letters = display_case == :upper ? out_letters.upcase : out_letters.downcase
      end
      
      plain_trunc, is_plain_trunc = Codec::Views.truncate(res.plain_bytes, limit: DISPLAY_LIMIT_BYTES)
      
      sugg_filename = input_type == 'text' ? "pesan-#{cipher_id}.dat" : "#{input_hash[:filename]}.dat"
      
      JSON.generate({
        ok: true,
        cipher: cipher_id,
        input: {
          kind: res.kind.to_s,
          filename: res.filename,
          bytes: input_hash[:bytes] ? input_hash[:bytes].bytesize : input_hash[:text].bytesize,
          encoding: res.encoding.to_s,
          used_symbols: res.used_symbols,
          plain_base64: Codec::Views.base64(plain_trunc),
          plain_truncated: is_plain_trunc,
          plain_total_bytes: res.plain_bytes.bytesize
        },
        output: {
          letters: out_letters,
          base64: b64,
          base64_truncated: is_truncated,
          hex: hex_val,
          hex_truncated: is_truncated,
          total_bytes: res.payload.bytesize
        },
        container_b64: [res.container].pack('m0'),
        suggested_filename: sugg_filename,
        key_info: res.key_info
      })
    end

    post '/api/decrypt' do
      cipher_id = params[:cipher] || halt(400, JSON.generate({ ok: false, error: 'invalid_input', field: 'cipher', message: 'Parameter cipher wajib diisi' }))
      
      cipher_class = Registry.all.find { |c| c.id == cipher_id }
      halt 404, JSON.generate({ ok: false, error: 'unsupported_cipher', message: 'Cipher tidak didukung' }) unless cipher_class
      
      begin
        c_params = JSON.parse(params[:params] || '{}')
      rescue JSON::ParserError
        halt 400, JSON.generate({ ok: false, error: 'invalid_params', message: 'Parameter kunci tidak valid' })
      end
      
      source = params[:source]
      unless %w[container text].include?(source)
        halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: 'source', message: 'Sumber harus container atau text' })
      end
      
      source_hash = { type: source.to_sym }
      
      if source == 'container'
        file_hash = params[:file]
        halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: 'file', message: 'Berkas wajib diunggah' }) unless file_hash && file_hash[:tempfile]
        file_bytes = file_hash[:tempfile].read
        file_hash[:tempfile].close
        file_hash[:tempfile].unlink if file_hash[:tempfile].respond_to?(:unlink)
        source_hash[:bytes] = file_bytes
      else
        txt = params[:text]
        txt = txt.gsub("\r\n", "\n") if txt
        halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: 'text', message: 'Teks wajib diisi' }) if txt.nil?
        if txt.bytesize > MAX_UPLOAD_BYTES
          halt 413, JSON.generate({ ok: false, error: 'payload_too_large', message: 'Teks melebihi batas' })
        end
        
        fmt = params[:text_format]
        unless %w[letters base64 hex].include?(fmt)
          halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: 'text_format', message: 'Format teks tidak didukung' })
        end
        source_hash[:text] = txt
        source_hash[:format] = fmt.to_sym
      end
      
      res = Service.decrypt(cipher_id: cipher_id, params: c_params, source: source_hash)
      
      mime_guess = 'application/octet-stream'
      if res.filename && !res.filename.empty?
        ext = File.extname(res.filename).downcase
        mime_guess = MIME_TYPES[ext] || 'application/octet-stream'
      end
      
      plain_trunc, is_plain_trunc = Codec::Views.truncate(res.plain_bytes, limit: DISPLAY_LIMIT_BYTES)
      
      ret = {
        ok: true,
        cipher: cipher_id,
        kind: res.kind.to_s,
        encoding: res.encoding.to_s,
        filename: res.filename,
        text: res.text,
        text_valid: res.text_valid,
        plain_base64: Codec::Views.base64(plain_trunc),
        plain_truncated: is_plain_trunc,
        plain_total_bytes: res.plain_bytes.bytesize,
        mime_guess: mime_guess,
        integrity: res.integrity,
        key_info: res.key_info
      }
      
      if res.kind == :file || params[:full_b64] == 'true'
        ret[:plain_full_b64] = [res.plain_bytes].pack('m0')
      end
      
      JSON.generate(ret)
    end

    post '/api/inspect' do
      file_hash = params[:file]
      halt 400, JSON.generate({ ok: false, error: 'invalid_input', field: 'file', message: 'Berkas wajib diunggah' }) unless file_hash && file_hash[:tempfile]
      
      file_bytes = file_hash[:tempfile].read
      file_hash[:tempfile].close
      file_hash[:tempfile].unlink if file_hash[:tempfile].respond_to?(:unlink)
      
      begin
        c = Container.unpack(file_bytes)
      rescue CipherWorkbench::InvalidContainerError => e
        halt 400, JSON.generate({ ok: false, error: 'invalid_container', message: e.message })
      end
      
      JSON.generate({
        ok: true,
        cipher: c.cipher_id,
        kind: c.kind.to_s,
        encoding: c.encoding.to_s,
        filename: c.filename,
        plain_length: c.plain_length,
        payload_length: c.payload.bytesize,
        format_version: 1
      })
    end
  end
end
