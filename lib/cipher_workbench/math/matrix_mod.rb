module CipherWorkbench
  module Math
    module MatrixMod
      class << self
        def identity(n)
          Array.new(n) { |i| Array.new(n) { |j| i == j ? 1 : 0 } }
        end

        def multiply(a, b, mod)
          n = a.length
          m = b[0].length
          p = a[0].length
          
          res = Array.new(n) { Array.new(m, 0) }
          n.times do |i|
            m.times do |j|
              sum = 0
              p.times do |k|
                sum += a[i][k] * b[k][j]
              end
              res[i][j] = Modular.normalize(sum, mod)
            end
          end
          res
        end

        def mat_vec(a, v, mod)
          n = a.length
          res = Array.new(n, 0)
          n.times do |i|
            sum = 0
            n.times do |j|
              sum += a[i][j] * v[j]
            end
            res[i] = Modular.normalize(sum, mod)
          end
          res
        end

        def determinant(a)
          n = a.length
          return a[0][0] if n == 1
          return a[0][0] * a[1][1] - a[0][1] * a[1][0] if n == 2
          
          det = 0
          n.times do |j|
            minor = a[1..-1].map { |row| row[0...j] + row[j+1..-1] }
            det += ((-1) ** j) * a[0][j] * determinant(minor)
          end
          det
        end

        def adjugate(a)
          n = a.length
          return [[1]] if n == 1
          
          cofactors = Array.new(n) { Array.new(n, 0) }
          n.times do |i|
            n.times do |j|
              minor = a.map.with_index { |row, r| row.reject.with_index { |_, c| c == j } unless r == i }.compact
              cofactors[i][j] = ((-1) ** (i + j)) * determinant(minor)
            end
          end
          
          # transpose
          cofactors.transpose
        end

        def inverse(a, mod)
          det = determinant(a)
          det_mod = Modular.normalize(det, mod)
          
          unless Modular.coprime?(det_mod, mod)
            gcd = Modular.gcd(det_mod, mod)
            raise InvalidKeyError.new(
              "Matriks tidak dapat diinvers (determinan mod #{mod} adalah #{det_mod}, gcd(#{det_mod}, #{mod}) = #{gcd} bukan 1). Silakan pilih matriks lain.",
              field: 'matrix'
            )
          end
          
          det_inv = Modular.mod_inverse(det_mod, mod)
          adj = adjugate(a)
          
          n = a.length
          res = Array.new(n) { Array.new(n, 0) }
          n.times do |i|
            n.times do |j|
              res[i][j] = Modular.normalize(adj[i][j] * det_inv, mod)
            end
          end
          
          # Alasan memakai adjugate (bukan eliminasi Gauss-Jordan): 
          # 26 bukan bilangan prima sehingga tidak setiap elemen tak nol punya invers, 
          # dan operasi pembagian baris pada eliminasi Gauss-Jordan dapat gagal jika pivot tidak memiliki invers modulo 26.
          res
        end
      end
    end
  end
end
