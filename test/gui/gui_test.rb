require 'minitest/autorun'
require 'rack/test'
require_relative '../../app'

class GuiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def test_index_and_assets
    get '/'
    assert_equal 200, last_response.status
    
    # Memastikan aset css yang disebut di index bisa dimuat
    css_files = last_response.body.scan(/href="(\/css\/[^"]+\.css)"/).flatten
    assert css_files.length >= 4
    
    css_files.each do |css_file|
      get css_file
      assert_equal 200, last_response.status, "Gagal memuat #{css_file}"
    end
  end

  def test_dev_gallery_route
    # Default env is test/development
    get '/dev/gallery'
    assert_equal 200, last_response.status
    
    # Production env
    begin
      original_env = ENV['RACK_ENV']
      ENV['RACK_ENV'] = 'production'
      get '/dev/gallery'
      assert_equal 404, last_response.status
    ensure
      ENV['RACK_ENV'] = original_env
    end
  end

  def test_no_external_assets
    # Pindai semua file di public dan views
    files = Dir.glob(File.join(__dir__, '../../views/**/*')) + Dir.glob(File.join(__dir__, '../../public/**/*'))
    files.select! { |f| File.file?(f) }
    
    files.each do |file|
      content = File.read(file)
      # Cari http:// atau https://
      urls = content.scan(/https?:\/\/[a-zA-Z0-9\-\.]+/i)
      # Abaikan link w3.org (svg namespace)
      urls.reject! { |u| u.downcase.include?('w3.org') }
      assert urls.empty?, "Ditemukan referensi eksternal di #{file}: #{urls.join(', ')}"
    end
  end
end
