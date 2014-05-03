
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum* ;
  identifier = c_lower c_alnum* ;
  
  integer    = [0-9]+ ;
  float      = [0-9]+ '.' [0-9]+ ;
  
  
  strbody    = ( ^('"'|'\\') | '\\\\' | '\\"' )+ ;
  
  # "foo bar"
  #
  string     = (
    zlen     % { note_begin :string }
    '"'      % { note :string, :T_STRING_BEGIN; note :string }
    strbody  % { note :string, :T_STRING_BODY;  note :string }
    '"'      % { note :string, :T_STRING_END }
  );
  
  # :foo
  # :"bar baz"
  #
  symbol     = (
    ':'            % { note_begin :symbol }
    (
      (
        identifier % { note :symbol, :T_SYMBOL; }
      )
    | (
        '"'        % { note :symbol, :T_SYMSTR_BEGIN; note :symbol }
        strbody    % { note :symbol, :T_SYMSTR_BODY;  note :symbol }
        '"'        % { note :symbol, :T_SYMSTR_END; }
      )
    )
  );
  
  
  # Foo,Bar,Baz
  #
  constant_list = (
    zlen           % { note_begin :constant_list }
    constant       % { note :constant_list, :T_CONSTANT }
    (
      c_space*     % { note :constant_list }
      ','          % { note :constant_list, :T_CONST_SEP }
      c_space_nl*  % { note :constant_list }
      constant     % { note :constant_list, :T_CONSTANT }
    )*
  );
  
  # Foo <
  #
  cdefn_begin = (
    zlen      % { note_begin :cdefn_begin }
    constant  % { note :cdefn_begin, :T_CONSTANT }
    c_space*  % { note :cdefn_begin }
    '<'       % { note :cdefn_begin, :T_DEFINE }
  ) % {
    emit_notes :cdefn_begin
  };
  
  # Object {
  #
  decl_begin = (
    (cdefn_begin c_space_nl*)?
    constant_list
    c_space_nl*  % { note_begin :decl_begin }
    '{'          % { note :decl_begin, :T_DECLARE_BEGIN }
  ) % {
    emit_notes :constant_list
    emit_notes :decl_begin
  };
  
  # Starting delimiter for a string declaration
  #
  # Can be any string of characters following a
  # constant name + whitespace that is not ambiguous
  # with some other construction
  #
  # The ending delimiter will be calculated from as follows:
  # The string of characters is reversed.
  # If there are groups of "alphabetical" characters,
  # the intra-group order remains intact.
  # If there are non-alphabetical characters with "directionality",
  # the "opposite" characters are substituted.
  #
  dstr_delim = (
    ^(c_space_nl|'{'|':'|',')
    ^(c_space_nl)+
  );
  
  # Object @@@
  #   ...
  # @@@
  #
  dstr_begin = (
    constant_list
    c_space+    % { mark :space }
    dstr_delim  % { grab :delim, kram(:space) }
  ) % {
    emit_notes :constant_list
    
    start, stop = @stored[:delim]
    emit :T_DECLSTR_BEGIN, start, stop
    
    # Table of replacement characters to use when calculating
    # the ending delimiter from the starting delimiter.
    # Directional characters are replaced with their opposite.
    @dstr_replace_table ||= %w{
      < > ( ) { } [ ]
    }
    
    # Calculate the ending delimiter to look for and store it
    @dstr_delim = text(start, stop) \
      .split(/(?<=[^a-zA-Z])|(?=[^a-zA-Z])/)
      .map { |str|
        idx = @dstr_replace_table.find_index(str)
        idx.nil? ? str : 
          (idx.odd? ? @dstr_replace_table[idx-1] : @dstr_replace_table[idx+1])
      }
      .reverse
      .join ''
  };
  
  # identifier (
  #
  args_begin = (
    zlen               % { note_begin :args_begin }
    identifier         % { note :args_begin, :T_IDENTIFIER }
    c_space_nl*        % { note :args_begin }
    '('                % { note :args_begin, :T_ARGS_BEGIN }
  );
  
  ##
  # Top level machine
  
  main := |*
    c_space_nl;
    
    decl_begin  => { fcall decl_body; };
    dstr_begin  => { fcall dstr_body; };
    
    constant   => { emit :T_CONSTANT };
    identifier => { emit :T_IDENTIFIER };
    string     => { emit_notes :string };
    
    ':' => { fcall pre_bind; };
    
    '}' => { emit :T_DECLARE_END; fret; };
    
    c_eof;
    any => { error :main };
  *|;
  
  ##
  # Declarative body machine
  
  decl_body := |*
    c_space_nl;
    
    decl_begin  => { fcall decl_body; };
    dstr_begin  => { fcall dstr_body; };
    
    constant   => { emit :T_CONSTANT };
    identifier => { emit :T_IDENTIFIER };
    string     => { emit_notes :string };
    
    ':' => { fcall pre_bind; };
    
    '}' => { emit :T_DECLARE_END; fret; };
    
    any => { error :decl_body };
  *|;
  
  ##
  # Pre-binding body sub-machine
  
  pre_bind := |*
    c_space_nl+;
    
    # Parameters are specified within '|'s
    '|'   => { emit :T_PARAMS_BEGIN; bpush :param; fcall bind_body; };
    
    # A binding begins with either a '{' or some other item for inline
    ^(c_space_nl|'{'|'|') =>
      { fhold; emit :T_BINDING_BEGIN, @ts, @ts; bpush :binl; fgoto bind_body; };
    '{'   => { emit :T_BINDING_BEGIN;           bpush :bind; fgoto bind_body; };
    
    any => { error :pre_bind };
  *|;
  
  ##
  # Declarative string machine
  
  dstr_body := |*
    (
      c_nl     % { mark :newline }
      (^c_nl)* % { grab :line, kram(:newline) }
    ) => {
      start, stop = @stored[:line];
      line_text = text start, stop
      
      raise "No known delimiter for string declaration." \
        if @dstr_delim.nil?
      
      if (line_text =~ /^(\s*)(\S+)/; $2==@dstr_delim)
        emit :T_DECLSTR_BODY, *@dstr_body_start, start
        @dstr_body_start = nil
        @dstr_delim = nil
        
        emit :T_DECLSTR_END, start+$1.size, stop
        fret;
      else
        @dstr_body_start ||= start
      end
    };
  *|;
  
  ##
  # Binding body machine
  
  bind_body := |*
    c_space+;
    
    decl_begin => { fcall decl_body; };
    dstr_begin => { fcall dstr_body; };
    
    args_begin => { emit_notes :args_begin; bpush :args;  fcall bind_body; };
    '('        => { emit :T_PAREN_BEGIN;    bpush :paren; fcall bind_body; };
    '['        => { emit :T_ARRAY_BEGIN;    bpush :array; fcall bind_body; };
    
    'nil'      => { emit :T_NIL };
    'true'     => { emit :T_TRUE };
    'false'    => { emit :T_FALSE };
    integer    => { emit :T_INTEGER };
    float      => { emit :T_FLOAT };
    constant   => { emit :T_CONSTANT };
    identifier => { emit :T_IDENTIFIER };
    '.'        => { emit :T_DOT };
    '+'        => { emit :T_OP_PLUS };
    '-'        => { emit :T_OP_MINUS };
    '*'        => { emit :T_OP_MULT };
    '/'        => { emit :T_OP_DIV };
    '%'        => { emit :T_OP_MOD };
    '**'       => { emit :T_OP_EXP };
    ('<'|'>'|'<='|'>='|'=='|'==='|'<=>'|'=~')
               => { emit :T_OP_COMPARE };
    
    symbol     => { emit_notes :symbol };
    string     => { emit_notes :string };
    
    '\\\n';    # Escaped newline - ignore
    
    ',' => {
      case bthis
      when :args;  emit :T_ARG_SEP
      when :param; emit :T_ARG_SEP
      when :array; emit :T_ARG_SEP
      else;        error :bind_body
      end
    };
    ';' => {
      case bthis
      when :bind;  emit :T_EXPR_SEP
      when :binl;  emit :T_EXPR_SEP
      when :paren; emit :T_EXPR_SEP
      else;        error :bind_body
      end
    };
    c_eol => {
      case bthis
      when :bind;  emit :T_EXPR_SEP
      when :binl;  emit :T_BINDING_END, @ts, @ts; bpop; fret;
      when :paren; emit :T_EXPR_SEP
      when :args;  emit :T_ARG_SEP
      when :array; emit :T_ARG_SEP
      else;        error :bind_body
      end
    };
    '}' => {
      case bthis
      when :bind;  emit :T_BINDING_END; bpop; fret;
      else;        error :bind_body
      end
    };
    ')' => {
      case bthis
      when :args;  emit :T_ARGS_END;  bpop; fret;
      when :paren; emit :T_PAREN_END; bpop; fret;
      else;        error :bind_body
      end
    };
    ']' => {
      case bthis
      when :array; emit :T_ARRAY_END; bpop; fret;
      else;        error :bind_body
      end
    };
    '|' => {
      case bthis
      when :param; emit :T_PARAMS_END; bpop; fret;
      else;        error :bind_body
      end
    };
    
    any => { error :bind_body };
  *|;
  
}%%
# %
