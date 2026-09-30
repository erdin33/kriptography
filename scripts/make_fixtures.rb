require 'zlib'
require 'fileutils'

DIR = File.expand_path('../../fixtures/generated', __FILE__)
FileUtils.mkdir_p(DIR)

def write_file(name, content)
  File.binwrite(File.join(DIR, name), content)
end

# 1. Teks ID
teks_id = <<~TEXT
Di bawah sinar bulan purnama, air laut berkilauan, berayun-ayun ombak mengalir ke pantai senda gurauan.
Angka 1234567890 dan tanda baca !@#$%^&*() juga harus dienkripsi dengan baik.
Bila sistem ini aman, maka data 99% terlindungi dari pihak ketiga.
TEXT
write_file('teks_id.txt', teks_id)

# 2. Unicode
unicode_txt = "Teks dengan Unicode: 🚀, 漢字, こんにちは, الأبجدية العربية, © 2026."
write_file('unicode.txt', unicode_txt)

# 3. Binary files
srand(42)
write_file('acak_1kb.bin', Array.new(1024) { rand(256) }.pack('C*'))
write_file('acak_1mb.bin', Array.new(1024 * 1024) { rand(256) }.pack('C*'))
write_file('nol_64kb.bin', "\x00" * 65536)
write_file('ff_64kb.bin', "\xFF" * 65536)
write_file('kosong.bin', "")
write_file('satu_byte.bin', "\x42")

# 4. PNG
def chunk(type, data)
  [data.bytesize].pack('N') + type + data + [Zlib.crc32(type + data)].pack('N')
end

width = 64
height = 64
# Minimal PNG header
png = "\x89PNG\r\n\x1a\n".b
# IHDR
ihdr_data = [width, height, 8, 2, 0, 0, 0].pack('NNCCCCC')
png << chunk("IHDR", ihdr_data)
# IDAT (gradient)
raw_data = ""
height.times do |y|
  raw_data << "\x00" # Filter type 0 (none)
  width.times do |x|
    raw_data << [x * 4, y * 4, 128].pack('CCC') # RGB
  end
end
compressed_data = Zlib::Deflate.deflate(raw_data)
png << chunk("IDAT", compressed_data)
# IEND
png << chunk("IEND", "")
write_file('gambar.png', png)

# 5. WAV (PCM 16-bit mono 440Hz 1s)
sample_rate = 44100
duration = 1
samples = sample_rate * duration
audio_data = ""
samples.times do |i|
  t = i.to_f / sample_rate
  val = (Math.sin(2 * Math::PI * 440 * t) * 32767).to_i
  audio_data << [val].pack('v') # 16-bit little endian
end
header = "RIFF"
file_size = 36 + audio_data.bytesize
header << [file_size].pack('V')
header << "WAVE"
header << "fmt "
header << [16].pack('V') # Subchunk1Size (16 for PCM)
header << [1].pack('v')  # AudioFormat (1 for PCM)
header << [1].pack('v')  # NumChannels (1 mono)
header << [sample_rate].pack('V')
header << [sample_rate * 2].pack('V') # ByteRate
header << [2].pack('v')  # BlockAlign
header << [16].pack('v') # BitsPerSample
header << "data"
header << [audio_data.bytesize].pack('V')
write_file('suara.wav', header + audio_data)

# 6. PDF Minimal
pdf = <<~PDF
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> >>
endobj
4 0 obj
<< /Length 53 >>
stream
BT
/F1 24 Tf
100 700 Td
(Hello Cipher Workbench PDF) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000288 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
390
%%EOF
PDF
write_file('dokumen.pdf', pdf)

puts "Berhasil membuat berkas fixture sintetik di #{DIR}"
