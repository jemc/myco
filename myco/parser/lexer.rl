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
    attr_reader :eof
    
    
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
      %% write exec;
      # %
      
      return @tokens.shift
    end
    
    
    %%{
    # %
      variable p  @p;
      variable ts @ts;
      variable te @te;
      
      action do_nl {
        @line += 1;
      }
      
      ## 
      # Basic character types -
      # Taken from https://github.com/whitequark/parser
      # Copyright (c) 2013 Peter Zotov  <whitequark@whitequark.org>
      # MIT License - see https://github.com/whitequark/parser/blob/master/LICENSE.txt
      
      c_nl       = '\n' $ do_nl;
      c_space    = [ \t\r\f\v];
      c_space_nl = c_space | c_nl;
      
      c_eof      = 0x04 | 0x1a | 0 | zlen; # ^D, ^Z, \0, EOF
      c_eol      = c_nl | c_eof;
      c_any      = any - c_eof;
      
      c_nl_zlen  = c_nl | zlen;
      c_line     = any - c_nl_zlen;
      
      c_unicode  = c_any - 0x00..0x7f;
      c_upper    = [A-Z];
      c_lower    = [a-z_]  | c_unicode;
      c_alpha    = c_lower | c_upper;
      c_alnum    = c_alpha | [0-9];
      
      # (end of basic character types)
      ##
      
      t_const = "Object";
      
      main := |* t_const => { p :t_const }; *|;
      
    }%%
    # %
    
  end
end
