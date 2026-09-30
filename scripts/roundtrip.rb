require_relative '../lib/cipher_workbench'
require_relative 'sample_keys'
require 'fileutils'
require 'digest'
require 'time'

# File paths
FIXTURES_DIRS = [
  File.expand_path('../../fixtures/generated', __FILE__),
  File.expand_path('../../fixtures/manual', __FILE__)
].freeze
TMP_DIR = File.expand_path('../../tmp/roundtrip', __FILE__)
EVIDENCE_DIR = File.expand_path('../../docs/evidence', __FILE__)

FileUtils.mkdir_p(TMP_DIR)
FileUtils.mkdir_p(EVIDENCE_DIR)

# Options
opts = { max_size: nil }
ARGV.each do |arg|
  if arg.start_with?('--max-size=')
    opts[:max_size] = arg.split('=').last.to_i
  end
end

# Find all files
files = FIXTURES_DIRS.flat_map { |dir| Dir.glob(File.join(dir, '*')) }.select { |f| File.file?(f) }

# Ciphers
ciphers = CipherWorkbench::Registry.catalog
# Skip hidden test ciphers
ciphers = ciphers.reject { |c| c[:group] == :internal }

# Results matrix [file][cipher] -> true/false/skip
matrix = {}
evidence = []

has_failure = false

# Known signatures
SIGNATURES = {
  '89504E47' => 'PNG',
  '25504446' => 'PDF',
  '504B0304' => 'ZIP/DOCX',
  'FFD8FF' => 'JPEG',
  '52494646' => 'WAV',
  '53514C69' => 'SQLite'
}

def identify_signature(bytes)
  hex = bytes[0..3].unpack1('H*').upcase
  SIGNATURES.each do |sig, name|
    return name if hex.start_with?(sig)
  end
  nil
end

total_start = Time.now

puts "=== Cipher Workbench Roundtrip QA ==="
puts "Total Files: #{files.size}"
puts "Total Ciphers: #{ciphers.size}"

files.each do |file|
  file_name = File.basename(file)
  file_data = File.binread(file)
  file_size = file_data.bytesize
  orig_sha256 = Digest::SHA256.hexdigest(file_data)
  orig_sig = identify_signature(file_data)
  
  matrix[file_name] = {}
  
  if opts[:max_size] && file_size > opts[:max_size]
    puts "\n--- Skipping #{file_name} (Size: #{file_size} > #{opts[:max_size]}) ---"
    ciphers.each do |c|
      matrix[file_name][c[:id]] = 'LEWAT'
    end
    next
  end

  puts "\n--- Berkas: #{file_name} (#{file_size} bytes) ---"

  ciphers.each do |cipher_meta|
    cipher_id = cipher_meta[:id]
    domain = cipher_meta[:domain]
    
    # 1. Enkripsi
    keys = SampleKeys.keys[cipher_id]
    
    t_start = Time.now
    enc_res = CipherWorkbench::Service.encrypt(
      cipher_id: cipher_id,
      params: keys,
      input: { kind: :file, bytes: file_data, filename: file_name }
    )
    t_enc = Time.now - t_start
    
    # Simpan
    container_bytes = enc_res.container
    tmp_path = File.join(TMP_DIR, "#{file_name}.#{cipher_id}.dat")
    File.binwrite(tmp_path, container_bytes)
    
    # Check signature encryption
    sig_hidden = 'N/A'
    if orig_sig
      if domain == :bytes
        # 8 byte pertama payload (setelah header container)
        container_struct = CipherWorkbench::Container.unpack(container_bytes)
        enc_payload = container_struct.payload
        enc_sig = enc_payload[0..3].unpack1('H*').upcase
        sig_hidden = (enc_sig != orig_sig) ? 'ya' : 'tidak'
        if sig_hidden == 'tidak'
          puts "  [#{cipher_id}] PERINGATAN: Tanda tangan #{orig_sig} tidak terenkripsi!"
          has_failure = true
        end
      else
        sig_hidden = 'ya (domain huruf)'
      end
    end
    
    # 2. Dekripsi
    t_start = Time.now
    dec_res = CipherWorkbench::Service.decrypt(
      cipher_id: cipher_id,
      params: keys,
      source: { type: :container, bytes: container_bytes }
    )
    t_dec = Time.now - t_start
    
    dec_bytes = dec_res.plain_bytes
    dec_sha256 = Digest::SHA256.hexdigest(dec_bytes)
    
    # 3. Bandingkan
    status = 'GAGAL'
    if dec_bytes == file_data && dec_res.filename == file_name && dec_res.integrity[:valid] == true
      status = 'LULUS'
    else
      puts "  [#{cipher_id}] GAGAL: Byte sama? #{dec_bytes == file_data}, Nama sama? #{dec_res.filename == file_name}, Integritas: #{dec_res.integrity[:valid]}"
      has_failure = true
    end
    
    matrix[file_name][cipher_id] = status
    
    puts format("  %-20s | %-6s | Enc: %6.3fs | Dec: %6.3fs | Sig hidden: %s", cipher_id, status, t_enc, t_dec, sig_hidden)
    
    evidence << {
      file: file_name,
      cipher: cipher_id,
      orig_size: file_size,
      enc_size: container_bytes.bytesize,
      orig_hex: file_data[0..31]&.unpack1('H*') || '',
      enc_hex: container_bytes[0..31]&.unpack1('H*') || '', # header container actually
      sha256_match: dec_sha256 == orig_sha256,
      status: status
    }
  end
end

total_time = Time.now - total_start

# --- Laporan MarkDown ---
date_str = Time.now.strftime('%Y%m%d_%H%M%S')
report_path = File.join(EVIDENCE_DIR, "roundtrip_#{date_str}.md")

File.open(report_path, 'w') do |f|
  f.puts "# Laporan QA Roundtrip"
  f.puts "- **Tanggal**: #{Time.now}"
  f.puts "- **Versi Ruby**: #{RUBY_VERSION}"
  f.puts "- **Kombinasi Tes**: #{evidence.size}"
  f.puts "- **Total Waktu**: #{total_time.round(2)} detik"
  
  f.puts "\n## Matriks Status"
  
  headers = ['Berkas'] + ciphers.map { |c| c[:id] }
  f.puts "| #{headers.join(' | ')} |"
  f.puts "| #{headers.map { '---' }.join(' | ')} |"
  
  matrix.each do |file, res|
    row = [file] + ciphers.map { |c| res[c[:id]] }
    f.puts "| #{row.join(' | ')} |"
  end
  
  f.puts "\n## Rincian Contoh"
  f.puts "| Berkas | Cipher | Ukuran Asli | Ukuran Cipherteks | 32 Byte Plain (Hex) | 32 Byte Cipherteks (Hex) | SHA256 Match | Status |"
  f.puts "|---|---|---|---|---|---|---|---|"
  evidence.each do |ev|
    f.puts "| #{ev[:file]} | #{ev[:cipher]} | #{ev[:orig_size]} | #{ev[:enc_size]} | `#{ev[:orig_hex]}` | `#{ev[:enc_hex]}` | #{ev[:sha256_match]} | #{ev[:status]} |"
  end
end

puts "\nSelesai. Laporan disimpan di #{report_path}"

exit(1) if has_failure
