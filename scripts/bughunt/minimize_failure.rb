#!/usr/bin/env ruby

module BugHunt
  module Minimizer
    # Simple minimization: try removing each element, if it still fails, keep it removed.
    def self.minimize(arr, &predicate)
      return arr if arr.empty? || !predicate.call(arr)
      
      # Try 1-minimal
      arr.size.times do |i|
        test_arr = arr.dup
        test_arr.delete_at(i)
        
        if predicate.call(test_arr)
          return minimize(test_arr, &predicate)
        end
      end
      
      arr
    end
  end
end
