require 'yaml'

asm_desc = ARGV[0]
asm = ARGV[1]

class Gasm
  def initialize(desc)
    @desc = desc
  end

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
              break if line[idx].nil? || line[idx] == ',' || line[idx] == ' '
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
      throw "unknown instruction #{line}"
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
    idx = result.length - 1
    varidx = 0

    lastvar = ' '
    output = ''
    loop do

      if values.key? result[idx]
        output = (values[result[idx]][-1 - varidx] || '.') + output
        lastvar = result[idx]
      else
        lastvar = ' '
        varidx = 0
        output = result[idx] + output
      end

      if result[idx] == lastvar
        varidx += 1
      else
        varidx = 0
      end

      idx -= 1
      break if idx < 0
    end

    "#{output}"
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
      parsed = @gasm.parse(line.strip)
      result << line
      result << "; #{parsed}\n" if parsed
    end

    result.join("\n")
  end
end

gasm = Gasm.new(YAML.load_file(asm_desc))
asm = Asm.new(File.read(asm), gasm)

puts asm.compiled
