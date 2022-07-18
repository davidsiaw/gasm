require 'yaml'
require 'gasm/ruby_desc'

module Gasm
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
      return yamldesc if @filename.end_with?('.yml')
  
      rubydesc
    end
  
    def yamldesc
      v = YAML.load_file(@filename)
  
      newhash = {}
      v['asm']['instructions'].each do |k, v|
        newhash[k] = {
          bits: v,
          condition: Proc.new {|x| true}
        }
      end
  
      v['asm']['instructions'] = newhash
      v
    end
  end
end
