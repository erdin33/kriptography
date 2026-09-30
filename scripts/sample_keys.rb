module SampleKeys
  def self.keys
    {
      'vigenere' => { 'key' => 'CIPHER' },
      'autokey' => { 'key' => 'CIPHER' },
      'playfair' => { 'key' => 'PLAYFAIR' },
      'affine' => { 'a' => '5', 'b' => '8' },
      'hill' => { 'n' => '2', 'matrix' => [['3', '3'], ['2', '5']] },
      'extended_vigenere' => { 'key' => 'SECRETKEY123' },
      'super' => { 'vigenere_key' => 'SECRET', 'transposition_key' => 'TRANS' },
      'enigma' => {
        'rotors' => 'I,II,III',
        'reflector' => 'B',
        'rings' => 'AAA',
        'positions' => 'AAA',
        'plugboard' => 'AB CD EF'
      }
    }
  end
end
