require 'minitest/autorun'
require_relative '../../lib/cipher_workbench/registry'

class FrontendContractsTest < Minitest::Test
  def test_schema_types_match_js
    js_content = File.read(File.expand_path('../../../public/js/schema_form.js', __FILE__))
    
    # Types supported based on js code
    supported_types = ['text', 'integer', 'matrix', 'rotor_set', 'plugboard']
    
    # Periksa apakah di js_content terdapat if (field.type === 'text') dsb
    supported_types.each do |type|
      assert js_content.include?("field.type === '#{type}'"), "JS schema_form.js missing explicit support for type: #{type}"
    end
    
    # Ensure all registry fields use supported types
    CipherWorkbench::Registry.catalog.each do |cipher|
      cipher[:fields].each do |field|
        assert supported_types.include?(field[:type]), "Cipher #{cipher[:id]} uses unknown field type: #{field[:type]}"
      end
    end
  end
end
