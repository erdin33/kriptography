require_relative 'extended_vigenere_oracle'
require_relative 'columnar_oracle'

module SuperOracle
  def self.decrypt(params, symbols)
    vigenere_key = params['vigenere_key']
    transposition_key = params['transposition_key']
    
    # Decrypt stage 1: Columnar Transposition
    col_symbols = ColumnarOracle.decrypt({'key' => transposition_key}, symbols)
    
    # Decrypt stage 2: Extended Vigenere
    ExtendedVigenereOracle.decrypt({'key' => vigenere_key}, col_symbols)
  end
end
