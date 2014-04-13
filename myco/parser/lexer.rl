%% machine lexer;
# %

module Myco::ToolSet
  class Parser
    class Lexer
      # See below
    end
  end
end

class Myco::ToolSet::Parser::Lexer
  %% write data;
  # %
  
  class << self
    attr_reader :data
    
    attr_reader :p
    attr_reader :pe
    attr_reader :cs
    
    
    def reset data=nil
      @data = data.unpack 'U*' if data
      @line = 1
      @tokens = []
    end
    
    
    def lex data
      reset data
      
      @p ||= 0
      @pe ||= data.length
      @cs = lexer_start
      
      all_tokens = []
      
      while token = advance
        all_tokens << token
      end
      
      return all_tokens
    end
    
    
    def advance
      p = @p
      %% write exec;
      # %
      @p = p
      
      return @tokens.shift
    end
    
    
    def add_token type, *args
      @tokens << [type, *args]
    end
    
    
    %%{
    # %
      c_hello = "h";
      c_world = "w";
      
      main := |*
        c_hello => { add_token :hello };
        c_world => { add_token :world };
      *|;
    }%%
    # %
    
  end
end
