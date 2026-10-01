require 'minitest/autorun'

class Bug005CrlfNormalizationTest < Minitest::Test
  def test_crlf_normalization_due_to_form_data
    # I12 Integritas UI: UI tidak mengubah data secara diam-diam.
    
    # Pada browser, FormData.append('text', "A\nB") dikirim sebagai "A\r\nB".
    # Karena API kita menerima input form-data, ia mendapatkan \r\n.
    # Kita buat tes RED yang menegaskan bahwa API kita saat ini merusak teks 
    # karena tidak mensterilkan kembali \r\n menjadi \n di backend.
    
    # Kita tidak punya browser, tapi kita tahu Service.encrypt tidak mengubah \r\n menjadi \n.
    
    require_relative '../../../lib/cipher_workbench'
    
    # Simulasikan apa yang diterima backend dari FormData (yaitu \r\n)
    input_received = "A\r\nB"
    
    res = CipherWorkbench::Service.encrypt(
      cipher_id: 'extended_vigenere',
      params: { 'key' => 'K' },
      input: { kind: :text, text: input_received }
    )
    
    # Harusnya backend mengembalikan plain_bytes yang steril dari mutasi browser,
    # atau frontend tidak menggunakan FormData untuk data presisi byte.
    
    # Test will fail if we expect it to not have \r
    assert_equal "A\nB", res.plain_bytes, "Melanggar I12: Teks dengan baris baru bermutasi menjadi CRLF dan tidak dibersihkan"
  end
end
