# gameboy cpu instructions
# refs:
# http://marc.rawer.de/Gameboy/Docs/GBCPUman.pdf
# https://meganesulli.com/generate-gb-opcodes/

TARGETS = %w[B C D E H L (HL) A]
CB = "1100 1011"

asm do
  instructions do

    def tbit(i)
      i.to_s(2).rjust(3,'0')
    end

    def dbit(i)
      i.to_s(2).rjust(2,'0')
    end

    def hexop(name, hex)
      op name, hex.to_s(2).rjust(8, '0')
    end


    %w[00 08 10 18 20 28 30 38].each do |pos|
      op "rst $#{pos}", "11 #{(pos.to_i(16)+7).to_s(2)}"
    end

    %w[NZ Z NC C].each_with_index do |cond, i|
      op "jp #{cond}, <n>",   "110 #{dbit(i)} 010 nnnn nnnn nnnn nnnn"
      op "jr #{cond}, <n>",   "001 #{dbit(i)} 000 nnnn nnnn"
      op "call #{cond}, <n>", "110 #{dbit(i)} 100 nnnn nnnn nnnn nnnn"
      op "ret #{cond}",       "110 #{dbit(i)} 000"
    end

    op "jp (HL)",  "1110 1001"
    op "jp <n>",   "1100 0011 nnnn nnnn nnnn nnnn"
    op "jr <n>",   "0001 1000 nnnn nnnn"
    op "call <n>", "1100 1101 nnnn nnnn nnnn nnnn"
  
    %w[rlc rrc rl rr sla sra swap srl].each_with_index do |oper, opidx|
      TARGETS.each_with_index do |reg, i|
        op "#{oper} #{reg}"          , "#{CB} 00 #{tbit(opidx)} #{tbit(i)}"
      end
    end

    TARGETS.each_with_index do |reg, i|
      op "bit <b>, #{reg}"          , "#{CB} 01 bbb #{tbit(i)}"
      op "res <b>, #{reg}"          , "#{CB} 10 bbb #{tbit(i)}"
      op "set <b>, #{reg}"          , "#{CB} 11 bbb #{tbit(i)}"
    end

    op "stop", "0001 0000 0000 0000"

    hexop "daa", 0x27
    hexop "cpl", 0x2f
    hexop "ccf", 0x3f
    hexop "scf", 0x37

    hexop "reti", 0xd9
    hexop "ret", 0xc9

    hexop "nop", 0x00
    hexop "halt", 0x76

    hexop "di", 0xf3
    hexop "ei", 0xfb
    
    hexop "rlca", 0x07
    hexop "rla", 0x17
    hexop "rrca", 0x0f
    hexop "rra", 0x1f

    # 16-bit arithmetic
    %w[BC DE HL SP].each_with_index do |reg, i|
      op "add HL, #{reg}"       , "00 #{dbit(i)} 1001"
      op "inc #{reg}", "00 #{dbit(i)} 0011"
      op "dec #{reg}", "00 #{dbit(i)} 1011"
    end
    
    # 8-bit arithmetic
    %w[add adc sub sbc and xor or cp].each_with_index do |oper, operidx|
      TARGETS.each_with_index do |reg, i|
        op "#{oper} A, #{reg}"         , "10 #{tbit(operidx)} #{tbit(i)}"
      end
  
      op "#{oper} A, <n>"            , "11 #{tbit(operidx)} 110 nnnn nnnn"
    end
    
    TARGETS.each_with_index do |reg, i|
      op "inc #{reg}"         , "00 #{tbit(i)} 100"
      op "dec #{reg}"         , "00 #{tbit(i)} 101"
    end

    op "add SP, <n>", "1110 1000 nnnn nnnn"
    
    # stack
    %w[BC DE HL AF].each_with_index do |reg, i|
      op "pop #{reg}"           , "11 #{dbit(i)} 0001"
    end
    
    %w[BC DE HL AF].each_with_index do |reg, i|
      op "push #{reg}"           , "11 #{dbit(i)} 0101"
    end
    
    op "ld (<n>), SP", "0000 1000  nnnn nnnn nnnn nnnn"
    
    op "ld HL, SP + <n>", "1111 1000  nnnn nnnn nnnn nnnn"

    # hl -> sp
    op "ld SP, HL", "1111 1001"

    # immediate 16-bit loads
    %w[BC DE HL SP].each_with_index do |reg, i|
      op "ld #{reg}, <n>"           , "00 #{dbit(i)} 0001 nnnn nnnn nnnn nnnn"
    end

    # register-register 8-bit loads
    TARGETS.each_with_index do |dreg, di|
      TARGETS.each_with_index do |sreg, si|
        op "ld #{dreg}, #{sreg}"           , "01 #{tbit(di)} #{tbit(si)}"
      end
    end

    # immediate 8-bit loads
    TARGETS.each_with_index do |reg, i|
      op "ld #{reg}, <n>"           , "00 #{tbit(i)} 110 nnnn nnnn"
    end
  
  end
end
