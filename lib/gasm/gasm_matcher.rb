module Gasm
  class GasmMatcher
    def initialize(desc)
      @desc = desc
    end
    
    def strip_spaces(line)
      line.sub(/([^%\$a-z0-9]) +/, '\1')
    end
    
    def strip_comment(line)
      line.split('//')[0]
    end

    def disparse(contents, index)
      match = nil

      @desc['asm']['instructions'].each do |k, info|
        bitpattern = info[:bits].tr(' ', '')
        
        vars = {}
        match = [k, info, vars, bitpattern.length >> 3]
        bitpattern.split('').each_with_index do |chr, i|
          byte_index = (i >> 3) + index
          bit_index = i % 8
          
          if byte_index >= contents.length
            match = nil
            next
          end

          contentbits = contents[byte_index].unpack("C")[0].to_s(2).rjust(8, '0')

          c = contentbits[bit_index]
          if chr == '0' || chr == '1'
            if c != chr
              match = nil
              break
            end
          else
            vars[chr] ||= ''
            vars[chr] += c
          end
        end

        break if match
      end

      raise 'unknown pattern' if match.nil?
      
      result = match[0]
      match[2].each do |var, val|
        result.gsub!("<#{var}>", "$#{val.to_i(2).to_s(16)}")
      end

      {
        amountread: match[3],
        instruction: result
      }
    end
    
    NUMCHARS = %[0 1 2 3 4 5 6 7 8 9 a b c d e f o x b $ %]
    def parse(line)
      line = strip_comment(line)
      line = strip_spaces(line)
      line = line.strip
      
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
      
      evalues = endiannize(values)
      loop do
        
        if result[idx] == lastvar
          varidx += 1
        else
          varidx = 0
        end
        
        if evalues.key? result[idx]
          output = (evalues[result[idx]][-1 - varidx] || '.') + output
          lastvar = result[idx]
        else
          lastvar = ' '
          varidx = 0
          output = result[idx] + output
        end
        
        #puts "#{evalues}, #{lastvar} #{varidx}"
        
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
    
    def littleendian(bitstr)
      # flips a bit string around to blocks of 8 little endian bytes
      # 1. reverse the string
      # 2. cut it into blocks of 8
      # 3. reverse each block of 8
      # 4. et voila
      bitstr.split('').reverse.each_slice(8).map{|x| x.reverse}.flatten.join('')
    end
    
    def endiannize(values)
      # transforms the values array into big and small endian versions
      result = {}
      values.each do |k,v|
        result[k] = littleendian(v)
        result[k.upcase] = v
      end
      result
    end
  end
end
