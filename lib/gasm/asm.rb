module Gasm
  class Asm
    def initialize(contents, gasm)
      @gasm = gasm
      @contents = contents
    end

    def output
      lines = @contents.split("\n")
      offset = 0

      result = []

      lines.each do |line|
        line.strip!
        next if line.length.zero? # Skip empty lines

        if line.start_with?('//') # Skip over comments
          result << line
          next
        end

        parsed = @gasm.parse(line)
        result << line
        result << "#{parsed}\n" if parsed
      end

      result.join("\n")
    end
  end
end
