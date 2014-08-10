
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum* ;
  identifier = c_lower c_alnum* ;
  
  comment    = '#' (any - c_eol)*; # end-of-line comment
  
  integer    = [0-9]+ ;
  float      = [0-9]+ '.' [0-9]+ ;
  
  strbody_norm = ^('\\' | '"');
  strbody      = strbody_norm* ('\\' c_any strbody_norm*)*;
  
  # "foo bar"
  #
  string     = (
    zlen     % { note_begin :string }
    '"'      % { note :string, :T_STRING_BEGIN; note :string }
    strbody  % { note :string, :T_STRING_BODY;  note :string }
    '"'      % { note :string, :T_STRING_END }
  );
  
  # [foo]
  #
  category = (
    zlen       % { note_begin :category }
    '['        % { note :category, :T_CATEGORY_BEGIN }
    c_space*   % { note :category }
    identifier % { note :category, :T_CATEGORY_BODY }
    c_space*   % { note :category }
    ']'        % { note :category, :T_CATEGORY_END }
  );
  
  # :foo
  # :"bar baz"
  #
  symbol = (
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
  
  # Foo
  # ::Bar
  # Foo::Bar
  # ::Foo::Bar::Baz
  #
  sconstant = (
    zlen         % { note_begin :sconstant }
    (
      '::'       % { note :sconstant, :T_SCOPE;    note :sconstant }
    )? (
      constant   % { note :sconstant, :T_CONSTANT; note :sconstant }
      '::'       % { note :sconstant, :T_SCOPE;    note :sconstant }
    )*
    constant     % { note :sconstant, :T_CONSTANT }
  );
  
  # Foo,Bar,Baz
  #
  constant_list = (
    zlen           % { note_begin :constant_list, nil }
    sconstant      % { xfer_notes :sconstant, :constant_list }
    (
      c_space*     % { note :constant_list }
      ','          % { note :constant_list, :T_CONST_SEP }
      c_space_nl*
      sconstant    % { xfer_notes :sconstant, :constant_list }
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
    c_space;
    comment;
    
    decl_begin  => { fcall decl_body; };
    dstr_begin  => { fcall dstr_body; };
    
    string     => { emit_notes :string };
    category   => { emit_notes :category };
    identifier => { emit :T_IDENTIFIER };
    constant   => { emit :T_CONSTANT };
    '::'       => { emit :T_SCOPE };
    
    ':' => { fcall pre_meme; };
    
    ';'  => { emit :T_EXPR_SEP };
    c_nl => { emit :T_EXPR_SEP };
    
    c_eof => { emit :T_DECLARE_END };
    any => { error :main };
  *|;
  
  ##
  # Declarative body machine
  
  decl_body := |*
    c_space;
    comment;
    
    (c_eol|';') => { emit :T_EXPR_SEP };
    
    decl_begin  => { fcall decl_body; };
    dstr_begin  => { fcall dstr_body; };
    
    string     => { emit_notes :string };
    category   => { emit_notes :category };
    identifier => { emit :T_IDENTIFIER };
    constant   => { emit :T_CONSTANT };
    '::'       => { emit :T_SCOPE };
    
    ':' => { fcall pre_meme; };
    
    '}' => { emit :T_DECLARE_END; fret; };
    
    any => { error :decl_body };
  *|;
  
  ##
  # Pre-meme body sub-machines
  
  pre_meme := |*
    c_space_nl+;
    comment;
    
    # Parameters are specified within '|'s
    '|'   => { emit :T_PARAMS_BEGIN; bpush :param; fcall meme_body; };
    
    # A meme begins with either a '{' or some other item for inline
    ^(c_space_nl|'{'|'|') =>
      { fhold; emit :T_MEME_BEGIN, @ts, @ts; bpush :meml; fgoto meme_body; };
    '{'   => { emit :T_MEME_BEGIN;           bpush :meme; fgoto meme_body; };
    
    any => { error :pre_meme };
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
  # Meme body machine
  
  meme_body := |*
    c_space+;
    comment;
    
    decl_begin => { fcall decl_body; };
    dstr_begin => { fcall dstr_body; };
    
    args_begin => { emit_notes :args_begin; bpush :args;  fcall meme_body; };
    '('        => { emit :T_PAREN_BEGIN;    bpush :paren; fcall meme_body; };
    '['        => { emit :T_ARRAY_BEGIN;    bpush :array; fcall meme_body; };
    '{'        => { emit :T_MEME_BEGIN;     bpush :meme;  fcall meme_body; };
    
    'self'     => { emit :T_SELF };
    'null'     => { emit :T_NULL };
    'void'     => { emit :T_VOID };
    'true'     => { emit :T_TRUE };
    'false'    => { emit :T_FALSE };
    integer    => { emit :T_INTEGER };
    float      => { emit :T_FLOAT };
    constant   => { emit :T_CONSTANT };
    identifier => { emit :T_IDENTIFIER };
    '.'        => { emit :T_DOT };
    '?'        => { emit :T_QUEST };
    '::'       => { emit :T_SCOPE };
    '='        => { emit :T_ASSIGN };
    '+'        => { emit :T_OP_PLUS };
    '-'        => { emit :T_OP_MINUS };
    '*'        => { emit :T_OP_MULT };
    '/'        => { emit :T_OP_DIV };
    '%'        => { emit :T_OP_MOD };
    '**'       => { emit :T_OP_EXP };
    ('<'|'>'|'<='|'>='|'=='|'==='|'<=>'|'=~')
               => { emit :T_OP_COMPARE };
    '&&'       => { emit :T_OP_AND };
    '||'       => { emit :T_OP_OR };
    
    symbol     => { emit_notes :symbol };
    string     => { emit_notes :string };
    
    '\\\n';    # Escaped newline - ignore
    
    
    '&' => {
      case bthis
      when :param; emit :T_OP_TOPROC
      else;        error :meme_body
      end
    };
    
    ',' => {
      case bthis
      when :args;  emit :T_ARG_SEP
      when :param; emit :T_ARG_SEP
      when :array; emit :T_ARG_SEP
      else;        error :meme_body
      end
    };
    
    ';' => {
      case bthis
      when :meme;  emit :T_EXPR_SEP
      when :meml;  emit :T_EXPR_SEP
      when :paren; emit :T_EXPR_SEP
      else;        error :meme_body
      end
    };
    
    c_eol => {
      case bthis
      when :meme;  emit :T_EXPR_SEP
      when :meml;  emit :T_MEME_END, @ts, @ts; fhold; bpop; fret;
      when :paren; emit :T_EXPR_SEP
      when :args;  emit :T_ARG_SEP
      when :param; emit :T_ARG_SEP
      when :array; emit :T_ARG_SEP
      else;        error :meme_body
      end
    };
    
    '}' => {
      case bthis
      when :meme;  emit :T_MEME_END; bpop; fret;
      else;        error :meme_body
      end
    };
    
    ')' => {
      case bthis
      when :args;  emit :T_ARGS_END;  bpop; fret;
      when :paren; emit :T_PAREN_END; bpop; fret;
      else;        error :meme_body
      end
    };
    
    ']' => {
      case bthis
      when :array; emit :T_ARRAY_END; bpop; fret;
      else;        error :meme_body
      end
    };
    
    '|' => {
      case bthis
      when :param; emit :T_PARAMS_END; bpop; fret;
      when :meme;  emit :T_PARAMS_BEGIN; bpush :param; fcall meme_body;
      when :meml;  emit :T_PARAMS_BEGIN; bpush :param; fcall meme_body;
      when :paren; emit :T_PARAMS_BEGIN; bpush :param; fcall meme_body;
      else;        error :meme_body
      end
    };
    
    any => { error :meme_body };
  *|;
  
}%%
# %
