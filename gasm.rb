require 'yaml'

asm_desc = ARGV[0]
asm_file = ARGV[1]

class Gasm
  def initialize(desc)
    @desc = desc
  end

  NUMCHARS = %[0 1 2 3 4 5 6 7 8 9 a b c d e f o x b $ %]
  def parse(line)
    result = ''
    values = {}
    idx = 0

    @desc['asm']['instructions'].each do |k, info|
      result = info[:bits]
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

      # parsing was not complete, so its not this one
      if line[idx] != nil
        result = nil
      end

      #p result, values, line, k
      # convert values to ints
      values = values.map do |k, v|
        int = 0
        if v.start_with?('0x')
          int = v[2..-1].to_i(16).to_s(2)
        elsif v.start_with?('$')
          int = v[1..-1].to_i(16).to_s(2)
        elsif v.start_with?('0b')
          int = v[2..-1].to_i(2).to_s(2)
        elsif v.start_with?('%')
          int = v[1..-1].to_i(2).to_s(2)
        elsif v.to_i.to_s == v
          int = v.to_i.to_s(2)
        else
          # we encounter a non-number or some symbol that makes no sense
          # this might not be the instruction we want.
          result = nil
          break
        end
        [k, int]
      end.to_h

      next if result.nil?

      # check the custom condition tagged on the opcode
      unless info[:condition].call(values.map{|k,v| [k.to_sym, v.to_i(2)]}.to_h)
        result = nil
      end

      break unless result.nil?
    end

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

  def op(pattern, bits, &block)
    info = {
      bits: bits,
      condition: lambda { |x| true }
    }
    info[:condition] = lambda { |x| block.call(x) } if block

    @ops << [pattern, info]
  end
end

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

if asm_desc.nil? || asm_file.nil?
  puts "USAGE: ruby gasm.rb <GASMFILE> <ASMFILE>"
  puts "GASMFILE can be a YML or Ruby file that is a GASM description."
  puts "ASMFILE is any text file that contains a series of assembly instructions separated"
  puts "  by newlines. You can also just write a dash and it will attempt to read from STDIN"
  exit(1)
end

if !File.exist?(asm_desc)
  puts "'#{asm_desc}' GASM file does not exist"
  exit(1)
end

begin
  gasm = Gasm.new(GasmLoader.new(asm_desc).desc)
rescue => e
  puts "Maybe invalid GASM file: #{e.message}"
  exit(1)
end

asm = if asm_file == '-'
        asm = Asm.new(STDIN.read, gasm)

      elsif
        if !File.exist?(asm_file)
          puts "'#{asm_file}' asm does not exist"
          exit(1)
        end

        asm = Asm.new(File.read(asm_file), gasm)
      end

puts asm.compiled
