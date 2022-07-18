module Gasm
  class OpSection
    attr_reader :pattern, :bits
    
    def initialize(ops)
      @ops = ops
    end
    
    def op(pattern, bits, &block)
      info = {
        bits: bits,
        condition: lambda { |x| true }
      }
      info[:condition] = lambda { |x| block.call(x) } if block
      
      @ops << [pattern, info]
    end
  end
end