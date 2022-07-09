# 6502 instructions
# refs:
# https://llx.com/Neil/a2/opcodes.html
# http://www.6502.org/tutorials/6502opcodes.html
# https://www.cs.otago.ac.nz/cosc243/pdf/6502Poster.pdf

asm do
  instructions do
    def impl_type_a_instr(opcodes, addrmodes, c)
      opcodes.each_with_index do |opcode, oi|
        addrmodes.each_with_index do |(pattern, zeropage, operands), ai|
          next if pattern.nil?
          next if pattern == '___'

          a = oi.to_s(2).rjust(3, '0')
          b = ai.to_s(2).rjust(3, '0')
          
          condition = Proc.new do true end
          condition = Proc.new do |x|
            x[:n] < 256
          end if zeropage
  
          op "#{opcode} #{pattern}", "#{a} #{b} #{c} #{'nnnn nnnn' * operands}", &condition
        end
      end
    end

    def hexop(name, hex, parambytes = 0)
      op name, hex.to_s(2).rjust(8, '0') + "nnnn nnnn" * parambytes
    end

    # addressing modes:
    
    ADDR_ZERO_IN_X = ['(<n>,X)', true , 1] # (zero page, X)
    ADDR_ZERO_PAGE = ['<n>',     true , 1] # zero page absolute
    ADDR_IMMEDIATE = ['#<n>',    false, 1] # #immediate
    ADDR_ABSOLUTE  = ['<n>',     false, 2] # absolute
    ADDR_ZERO_IN_Y = ['(<n>),Y', true , 1] # (zero page), Y
    ADDR_ZERO_X    = ['<n>,X',   true , 1] # zero page absolute, X
    ADDR_ZERO_Y    = ['<n>,Y',   true , 1] # zero page absolute, Y
    ADDR_ABS_Y     = ['<n>,Y',   false, 2] # absolute, Y
    ADDR_ABS_X     = ['<n>,X',   false, 2] # absolute, X
    ADDR_ACCUMULAT = ['A',       false, 0] # accumulator
    ADDR_INVALID   = []                    # invalid addressing mode

    # single byte instructions
    hexop 'brk', 0x00
    hexop 'nop', 0xea
    hexop 'rti', 0x40
    hexop 'rts', 0x60

    hexop 'php', 0x08
    hexop 'plp', 0x28
    hexop 'pha', 0x48
    hexop 'pla', 0x68

    hexop 'txs', 0x9a
    hexop 'tsx', 0xba

    hexop 'tay', 0xa8
    hexop 'tax', 0xaa

    hexop 'dex', 0xca
    hexop 'dey', 0x88

    hexop 'iny', 0xc8
    hexop 'inx', 0xe8

    hexop 'txa', 0x8a
    hexop 'tya', 0x98

    hexop 'clc', 0x18
    hexop 'cli', 0x58
    hexop 'clv', 0xb8
    hexop 'cld', 0xd8

    hexop 'sec', 0x38
    hexop 'sei', 0x78
    hexop 'sed', 0xf8
    
    # type aaabbbcc instructions (01)
    # I left sta #n in but its a nop anyway. it will generate the code without complaining
    opcodes = %w[ora and eor adc sta lda cmp sbc]

    addrmodes = [
      ADDR_ZERO_IN_X,
      ADDR_ZERO_PAGE,
      ADDR_IMMEDIATE,
      ADDR_ABSOLUTE,
      ADDR_ZERO_IN_Y,
      ADDR_ZERO_X,
      ADDR_ABS_Y,
      ADDR_ABS_X
    ]

    impl_type_a_instr(opcodes, addrmodes, '01')

    # type aaabbbcc instructions (10)
    # %w[asl rol lsr ror stx ldx dec inc]

    common = [
      ADDR_ZERO_PAGE,
      ADDR_ACCUMULAT,
      ADDR_ABSOLUTE,
      ADDR_INVALID,
    ]

    no_a = [
      ADDR_ZERO_PAGE,
      ADDR_INVALID,
      ADDR_ABSOLUTE,
      ADDR_INVALID,
    ]

    # zero page statements
    zerox = [ADDR_ZERO_X, ADDR_INVALID]
    zeroy = [ADDR_ZERO_Y, ADDR_INVALID]

    # absolute statements (only available in load)
    absx = [ADDR_ABS_X]
    absy = [ADDR_ABS_Y]

    # note: stx a and ldx a are basically txa and tax, so we allow it
    # note: stx abs,Y could actually exist but doesnt because it maps to an illegal instruction that is undefined.
    impl_type_a_instr(%w[___ ___ ___ ___ ___ ldx ___ ___], [ADDR_IMMEDIATE] + common + zeroy + absy, '10')
    impl_type_a_instr(%w[___ ___ ___ ___ stx ___ ___ ___], [ADDR_INVALID]   + common + zeroy       , '10')

    # note: dec a is the same as dex. so we allow it
    impl_type_a_instr(%w[asl rol lsr ror ___ ___ dec ___], [ADDR_INVALID]   + common + zerox + absx, '10')

    # inc cannot access the accumulator. that opcode is nop
    impl_type_a_instr(%w[___ ___ ___ ___ ___ ___ ___ inc], [ADDR_INVALID]   + no_a   + zerox + absx, '10')

    # type aaabbbcc instructions (00)
    # %w[___ bit ___ ___ sty ldy cpy cpx]

    # note: ldy a is the same as tay so we allow it. sty a if we use the normal accumulator
    #       pattern unfortunately leads to dey. we put in a special entry to map it to tya
    impl_type_a_instr(%w[___ ___ ___ ___ ___ ldy ___ ___], [ADDR_IMMEDIATE] + common + zerox + absx, '00')
    impl_type_a_instr(%w[___ ___ ___ ___ sty ___ ___ ___], [ADDR_INVALID]   + no_a   + zerox       , '00')
    hexop 'sty A', 0x98

    impl_type_a_instr(%w[___ ___ ___ ___ ___ ___ cpy cpx], [ADDR_IMMEDIATE] + no_a                 , '00')

    impl_type_a_instr(%w[___ bit ___ ___ ___ ___ ___ ___], [ADDR_INVALID]   + no_a                 , '00')

    # control flow instructions
    hexop 'jmp <n>',   0x4c, 2
    hexop 'jmp (<n>)', 0x6c, 2
    hexop 'jsr <n>',   0x20, 2

    hexop 'bpl',       0x10, 1
    hexop 'bmi',       0x30, 1
    hexop 'bvc',       0x50, 1
    hexop 'bvs',       0x70, 1

    hexop 'bcc',       0x90, 1
    hexop 'bcs',       0xb0, 1
    hexop 'bne',       0xd0, 1
    hexop 'beq',       0xf0, 1
  end
end
