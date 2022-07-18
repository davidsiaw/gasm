module Gasm
  class Disasm
    def initialize(contents, gasm)
      @gasm = gasm
      @contents = contents
    end
    
    def output
      result = []

      index = 0
      loop do
        res = @gasm.disparse(@contents, index)
        index += res[:amountread]
        result << res[:instruction]
        break if index >= @contents.length
      rescue => e
        result << "// -incomplete- disassembling stopped: #{e.message} at index 0x#{index.to_s(16)} '0x#{@contents[index].unpack('C')[0].to_s(16)}'"
        break
      end
      result.join("\n")
    end
  end
end
