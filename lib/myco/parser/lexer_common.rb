
class Myco::ToolSet::Parser
  class Lexer
    
    def reset_common
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
      @stored[name] = [text(start,stop), @line]
    end
    
    def stuff type, name
      add_token type, *@stored.delete(name)
    end
    
    def error(location, hint=nil)
      str = "Lexer met unexpected character(s) in #{location.inspect}: #{text.inspect}"
      str += "; "+hint.to_s if hint
      warn str
    end
    
  end
end
