
## 
# Basic Lexer skeleton - taken from gist:
#   https://gist.github.com/YorickPeterse/10658884
# Originally from:
#   https://github.com/YorickPeterse/oga/blob/master/lib/oga/xml/lexer.rl
#
# License for the source gist reproduced below.

# Copyright (c) 2014, Yorick Peterse
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

%%machine lexer; # %

class Myco::ToolSet::Parser
  class Lexer
    %% write data; # %
    
    ##
    # @param [String] data The data to lex.
    #
    def initialize(data)
      @data = data.unpack('U*') << 0
      
      reset
    end
    
    ##
    # Resets the internal state of the lexer. Typically you don't need to
    # call this method yourself as its called by #lex after lexing a given
    # String.
    #
    def reset
      @line     = 1
      @ts       = nil
      @te       = nil
      @tokens   = []
      @stack    = []
      @top      = 0
      @cs       = self.class.lexer_start
      @act      = 0
      @elements = []
      @eof      = @data.length
      @p        = 0
      @pe       = @eof
      reset_common
    end
    
    ##
    # Lexes the supplied String and returns an Array of tokens. Each token is
    # an Array in the following format:
    #
    #     [TYPE, VALUE]
    #
    # The type is a symbol, the value is either nil or a String.
    #
    # This method resets the internal state of the lexer after consuming the
    # input.
    #
    # @param [String] data The string to consume.
    # @return [Array]
    # @see #advance
    #
    def lex
      tokens = []
      
      while token = advance
        tokens << token
      end
      
      reset
      
      return tokens
    end
    
    ##
    # Advances through the input and generates the corresponding tokens.
    #
    # This method does *not* reset the internal state of the lexer.
    #
    # @param [String] data The String to consume.
    # @return [Array]
    #
    def advance
      _lexer_actions             = self.class.send :_lexer_actions
      _lexer_range_lengths       = self.class.send :_lexer_range_lengths
      _lexer_trans_actions       = self.class.send :_lexer_trans_actions
      _lexer_key_offsets         = self.class.send :_lexer_key_offsets
      _lexer_index_offsets       = self.class.send :_lexer_index_offsets
      _lexer_to_state_actions    = self.class.send :_lexer_to_state_actions
      _lexer_trans_keys          = self.class.send :_lexer_trans_keys
      _lexer_from_state_actions  = self.class.send :_lexer_from_state_actions
      _lexer_single_lengths      = self.class.send :_lexer_single_lengths
      _lexer_trans_targs         = self.class.send :_lexer_trans_targs
      _lexer_eof_trans           = self.class.send :_lexer_eof_trans
      # _lexer_indicies            = self.class.send :_lexer_indicies
      
      %% write exec;
      # %
      
      return @tokens.shift
    end
    
    private
    
    ##
    # Returns the text of the current buffer based on the supplied start and
    # stop position.
    #
    # By default `@ts` and `@te` are used as the start/stop position.
    #
    # @param [Fixnum] start
    # @param [Fixnum] stop
    # @return [String]
    #
    def text(start = @ts, stop = @te)
      return @data[start...stop].pack('U*')
    end
    
    
    %%{
    # %
      # Use instance variables for `ts` and friends.
      access @;
      getkey (@data[@p] || 0);
      variable p @p;
      variable pe @pe;
      variable eof @eof;
      
      action do_nl { do_nl }
      
      include "lexer_char_classes.rl"; # Basic character classes
      include "lexer.rl";              # Main rules file
    }%%
    # %
  end
end
