
class Myco::ToolSet::Parser
  class Lexer
    
    def reset_common
      @newlines = [0]
      @marks  = {}
      @stored = {}
    end
    
    def mark name, pos=@p
      @marks[name] = pos
    end
    
    def kram name
      @marks.delete name
    end
    
    def grab name, start=@ts, stop=@p
      @stored[name] = [start, stop]
    end
    
    def note_begin queue_name, pos=@p
      queue = @marks[queue_name] = [@p]
    end
    
    def note queue_name, type=nil, pos=@p
      queue = (@marks[queue_name] ||= [])
      queue << pos
      queue << type if type
      queue
    end
    
    def emit_notes queue_name
      queue = (@marks[queue_name] || [])
      queue.each_slice(3) { |a,b,c| emit c,a,b if a && b && c }
      queue.clear
    end
    
    def error(location, hint=nil)
      str = "Lexer met unexpected character(s) in #{location.inspect}: #{text.inspect}"
      str += "; "+hint.to_s if hint
      warn str
    end
    
    
    def do_nl
      @newlines << @p unless @newlines.include? @p
    end
    
    def emit(type, start = @ts, stop = @te)
      @tokens << [type, text(start,stop), locate(start)]
    end
    
    def locate index
      ary = @newlines.take_while { |i| i <= index }
      row, col = ary.size, index-ary.last+1
    end
    
  end
end
