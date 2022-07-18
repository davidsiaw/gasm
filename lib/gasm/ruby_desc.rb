require 'gasm/instruction_section'

module Gasm
  class RubyDesc
    attr_reader :desc

    def initialize
      @desc = {}
    end

    def asm(&block)
      insts = InstructionsSection.new
      insts.instance_eval(&block)
      @desc['asm'] = insts.inst
    end
  end
end
