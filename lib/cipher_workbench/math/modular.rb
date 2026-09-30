module CipherWorkbench
  module Math
    module Modular
      class << self
        def gcd(a, b)
          a, b = a.abs, b.abs
          while b != 0
            a, b = b, a % b
          end
          a
        end

        # Extended Euclidean Algorithm
        # Returns [gcd, x, y] such that a*x + b*y = gcd
        def egcd(a, b)
          return [b.abs, 0, b < 0 ? -1 : 1] if a == 0

          g, x, y = egcd(b % a, a)
          [g, y - (b / a) * x, x]
        end

        def coprime?(a, m)
          gcd(a, m) == 1
        end

        def mod_inverse(a, m)
          a = normalize(a, m)
          g, x, _ = egcd(a, m)
          raise InvalidKeyError.new("Balikan modulo untuk #{a} mod #{m} tidak ditemukan") if g != 1

          normalize(x, m)
        end

        def normalize(a, m)
          # Ruby's % operator on negative numbers returns a positive result
          # if the modulus is positive (e.g. -1 % 26 == 25).
          # However, let's just make sure it behaves correctly for our domain.
          ((a % m) + m) % m
        end
      end
    end
  end
end
