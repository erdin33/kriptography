require_relative '../test_helper'
require_relative '../support/test_ciphers'

class RegistryTest < Minitest::Test
  def test_registry_contains_test_ciphers
    assert_includes CipherWorkbench::Registry.all.map(&:id), 'shift_letters'
    assert_includes CipherWorkbench::Registry.all.map(&:id), 'shift_bytes'
  end

  def test_build_returns_instance
    cipher = CipherWorkbench::Registry.build('shift_letters', {})
    assert_instance_of CipherWorkbench::Ciphers::ShiftLetters, cipher
  end

  def test_build_raises_unsupported
    assert_raises(CipherWorkbench::UnsupportedCipherError) do
      CipherWorkbench::Registry.build('unknown_cipher', {})
    end
  end

  def test_catalog_returns_info
    catalog = CipherWorkbench::Registry.catalog
    shift = catalog.find { |c| c[:id] == 'shift_letters' }
    assert_equal 'Shift Letters Test', shift[:title]
  end
end
