require 'gasm/op_section'

module Gasm
  class InstructionsSection
    def initialize
      @ops = []
    end
    
    def inst
      {
        'instructions' => @ops
      }
    end
    
    def instructions(&block)
      op = OpSection.new(@ops)
      op.instance_eval(&block)
    end
  end
end