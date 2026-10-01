#!/usr/bin/env ruby
require 'json'
require_relative '../../lib/cipher_workbench'
require_relative '../../test/support/oracle_harness'

module BugHunt
  module Stagewise
    def self.diff(cipher_id, key, payload_symbols)
      puts "--- Stagewise Diff ---"
      puts "Cipher: #{cipher_id}"
      puts "Key: #{key.inspect}"
      puts "Payload Symbols: #{payload_symbols.inspect}"
      
      prod_cipher = CipherWorkbench::Registry.build(cipher_id, key)
      oracle = OracleHarness.oracle_for(cipher_id)
      
      oracle_out = oracle.decrypt(key, payload_symbols.dup)
      prod_out = prod_cipher.decrypt(payload_symbols.dup)
      
      puts "Oracle Out: #{oracle_out.inspect}"
      puts "Prod Out:   #{prod_out.inspect}"
      
      if oracle_out != prod_out
        puts "=> DIVERGE: Cipher Output"
      else
        puts "=> MATCH: Cipher Output"
      end
    end
  end
end

if __FILE__ == $0
  cipher = ARGV[0] || 'vigenere'
  key = JSON.parse(ARGV[1] || '{"key":"A"}')
  symbols = JSON.parse(ARGV[2] || '[0, 1, 2]')
  BugHunt::Stagewise.diff(cipher, key, symbols)
end
