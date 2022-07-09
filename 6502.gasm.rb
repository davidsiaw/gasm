# 6502 instructions
# refs:
# https://llx.com/Neil/a2/opcodes.html
# http://www.6502.org/tutorials/6502opcodes.html
# https://www.cs.otago.ac.nz/cosc243/pdf/6502Poster.pdf

asm do
  instructions do
    # type aaabbbcc instructions (01)
    # I left sta #n in but its a nop anyway. it will generate the code without complaining
    opcodes = %w[ora and eor adc sta lda cmp sbc]

    addrmodes = [
      ['(<n>,X)', true , 1], # (zero page, X)
      ['<n>',     true , 1], # zero page absolute
      ['#<n>',    false, 1], # #immediate
      ['<n>',     false, 2], # absolute
      ['(<n>),Y', true , 1], # (zero page), Y
      ['<n>,X',   true , 1], # zero page absolute, X
      ['<n>,Y',   false, 2], # absolute, Y
      ['<n>,X',   false, 2], # absolute, X
    ]

    opcodes.each_with_index do |opcode, oi|
      addrmodes.each_with_index do |(pattern, zeropage, operands), ai|
        a = oi.to_s(2).rjust(3, '0')
        b = ai.to_s(2).rjust(3, '0')
        
        condition = Proc.new do true end
        condition = Proc.new do |x|
          x[:n] < 256
        end if zeropage

        op "#{opcode} #{pattern}", "#{a} #{b} 01 #{'nnnn nnnn' * operands}", &condition
      end
    end

    # type aaabbbcc instructions (10)
    addrmodes = [
      ['#<n>',    false, 1], # #immediate
      ['<n>',     true , 1], # zero page absolute
      ['A',       false, 0], # accumulator
      ['<n>',     false, 2], # absolute
      [],
      ['<n>,X',   true , 1], # zero page absolute, X
      [],
      ['<n>,X',   false, 2], # absolute, X
    ]

    # ldx and ldy
    opcodes = %w[ldx ldy]



  end
end