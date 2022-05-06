require 'yaml'

asm_desc = ARGV[0]
asm = ARGV[1]

class Gasm
  def initialize(desc)
    @desc = desc
  end

  NUMCHARS = %[0 1 2 3 4 5 6 7 8 9 a b c d e f o x]
  def parse(line)
    result = ''
    values = {}
    idx = 0

    @desc['asm']['instructions'].each do |k, v|
      result = v
      idx = 0

      state = 'CHR'
      varname = ''

      values = {}
      k.split('').each do |chr|
        #p chr
        if state == 'VAR'
          if chr.ord >= 'a'.ord && chr.ord <= 'z'.ord
            varname = chr
            state = 'FIN'
          else
            throw "expected a-z but got #{chr}"
          end

        elsif state == 'FIN' && 
          if chr == '>'
            state = 'CHR'
            value = ''
            loop do
              break if line[idx].nil? || !NUMCHARS.include?(line[idx])
              value += line[idx]
              idx += 1
            end
            values[varname] = value
            
          else
            throw "expected > but got #{chr}"
          end

        elsif state == 'CHR'
          if chr == '<'
            state = 'VAR'
          elsif chr != line[idx]
            result = nil
            break
          else
            idx += 1
          end

        else
          throw "unknown state #{state} #{chr}"

        end
      end

      break unless result.nil?
    end

    if line[idx] != nil
      throw "unknown instruction [#{idx}]: #{line}"
    end

    # convert values to ints
    values = values.map do |k, v|
      int = 0
      if v.start_with?('0x')
        int = v[2..-1].to_i(16).to_s(2)
      elsif v.to_i.to_s == v
        int = v.to_i.to_s(2)
      else
        throw "don't know how to parse number '#{v}'"
      end
      [k, int]
    end.to_h

    if result.nil?
      throw "unknown instruction '#{line}'"
    end

    # fill in result
    result = result.to_s.gsub(/\s+/, '')
    idx = result.length - 1
    varidx = 0

    lastvar = ' '
    output = ''
    loop do

      if result[idx] == lastvar
        varidx += 1
      else
        varidx = 0
      end

      if values.key? result[idx]
        output = (values[result[idx]][-1 - varidx] || '.') + output
        lastvar = result[idx]
      else
        lastvar = ' '
        varidx = 0
        output = result[idx] + output
      end

      #puts "#{values}, #{lastvar} #{varidx}"

      idx -= 1
      break if idx < 0
    end

    # split array into groups of 8 bits
    toks = output.split('').each_slice(8)

    # rejoin the 8 bits in bsm format, and pad the end with zeros
    toks = toks.map do |x|
      "#{x.join('').ljust(8, '.')}"
    end
    
    # write down a byte breakdown in both dec and hex
    comment_line = toks.map{|x| x.tr('.', '0').to_i(2).to_s.ljust(11)}.join('')
    comment_line2 = toks.map{|x| ("0x" + x.tr('.', '0').to_i(2).to_s(16).rjust(2, '0')).ljust(11)}.join('')
    comment_line3 = toks.map{|x| ("0o" + x.tr('.', '0').to_i(2).to_s(8).rjust(3, '0')).ljust(11)}.join('')

    # generate the line that actually creates the bits
    command_line = toks.map{|x| "<#{x}>"}.join(' ')

    [
      "--",
      " d " + comment_line,
      " h " + comment_line2,
      " o " + comment_line3,
      "; " + command_line
    ].join("\n")
  end
end

class Asm
  def initialize(contents, gasm)
    @gasm = gasm
    @contents = contents
  end

  def compiled
    lines = @contents.split("\n")
    offset = 0

    result = []

    lines.each do |line|
      next if line.strip.start_with?(';') # Skip over comments
      next if line.strip.length.zero? # Skip empty lines

      parsed = @gasm.parse(line.strip)
      result << line
      result << "#{parsed}\n" if parsed
    end

    result.join("\n")
  end
end

class OpSection
  attr_reader :pattern, :bits

  def initialize(ops)
    @ops = ops
  end

  def op(pattern, bits)
    @ops[pattern] = bits
  end
end

class InstructionsSection
  def initialize
    @ops = {}
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

class GasmLoader
  def initialize(filename)
    @filename = filename
  end

  def rubydesc
    rbdesc = RubyDesc.new
    rbdesc.instance_eval(File.read(@filename), @filename)
    rbdesc.desc
  end

  def desc
    return YAML.load_file(@filename) if @filename.end_with?('.yml')

    rubydesc
  end
end

gasm = Gasm.new(GasmLoader.new(asm_desc).desc)
asm = Asm.new(File.read(asm), gasm)

puts asm.compiled
