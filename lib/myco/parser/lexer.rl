
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum*;
  identifier = c_lower c_alnum*;
  
  numeric    = '-'? [0-9]+ ('.' [0-9]+)?;
  
  
  # Foo,Bar,Baz
  #
  constant_list = (
    zlen           % { note_begin :constant_list }
    constant       % { note :constant_list, :T_CONSTANT }
    (
      c_space*     % { note :constant_list }
      ','          % { note :constant_list, :T_COMMA }
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
  
  # Object { ... }
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
  
  # |a, b, *args, c:4, d:5, **kwargs|
  #
  param_list = (
    zlen               % { note_begin :param_list }
    '|'                % { note :param_list, :T_PARAMS_BEGIN }
    c_space_nl*        % { note :param_list }
    (
      identifier       % { note :param_list, :T_IDENTIFIER }
      c_space*         % { note :param_list }
      (
        ','            % { note :param_list, :T_COMMA }
        c_space_nl*    % { note :param_list }
        identifier     % { note :param_list, :T_IDENTIFIER }
        c_space*       % { note :param_list }
      )*
    )?
    '|'                % { note :param_list, :T_PARAMS_END }
  );
  
  # foo: { ... }
  #
  bind_begin = (
    zlen                        % { note_begin :bind_begin_id }
    (
      identifier                % { note :bind_begin_id, :T_IDENTIFIER }
    | constant                  % { note :bind_begin_id, :T_CONSTANT }
    )
    (c_space* ':' c_space_nl*)
    param_list?
    (c_space_nl*)               % { note :bind_begin }
    '{'                         % { note :bind_begin, :T_BINDING_BEGIN }
  ) % {
    emit_notes :bind_begin_id
    emit_notes :param_list
    emit_notes :bind_begin
  };
  
  # foo: ...
  #
  binl_begin = (
    zlen                        % { note_begin :bind_begin_id }
    (
      identifier                % { note :bind_begin_id, :T_IDENTIFIER }
    | constant                  % { note :bind_begin_id, :T_CONSTANT }
    )
    (c_space* ':' c_space_nl*)
    param_list?
    (c_space_nl*)               % { note :bind_begin }
    ^(c_space_nl|'{'|'|')       % { fhold; note :bind_begin, :T_BINDING_BEGIN }
  ) % {
    emit_notes :bind_begin_id
    emit_notes :param_list
    emit_notes :bind_begin
  };
  
  ##
  # Top level machine
  
  main := |*
    c_space_nl;
    
    bind_begin => { fcall bind_body; };
    binl_begin => { fcall binl_body; };
    
    decl_begin => { fcall decl_body; };
    dstr_begin => { fcall dstr_body; };
    constant   => { emit :T_CONSTANT };
    
    c_eof;
    any => { error :main };
  *|;
  
  ##
  # Declarative body machine
  
  decl_body := |*
    c_space_nl;
    
    decl_begin  => { fcall decl_body; };
    dstr_begin  => { fcall dstr_body; };
    constant    => { emit :T_CONSTANT };
    
    bind_begin  => { fcall bind_body; };
    binl_begin  => { fcall binl_body; };
    identifier  => { emit :T_IDENTIFIER };
    
    '}' => { emit :T_DECLARE_END; fret; };
    
    any => { error :decl_body };
  *|;
  
  ##
  # String-related machines
  
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
  
  string_lit = (
    zlen    % { note_begin :string_lit }
    '"'     % { note :string_lit, :T_STRING_BEGIN; note :string_lit }
    (^'"')* % { note :string_lit, :T_STRING_BODY;  note :string_lit }
    '"'     % { note :string_lit, :T_STRING_END; }
  ) % {
    emit_notes :string_lit
  };
  
  ##
  # Binding body machines
  
  bind_body := |*
    c_space_nl;
    
    decl_begin => { fcall decl_body; };
    dstr_begin => { fcall dstr_body; };
    'nil'      => { emit :T_NIL };
    numeric    => { emit :T_NUMERIC };
    constant   => { emit :T_CONSTANT };
    identifier => { emit :T_IDENTIFIER };
    '('        => { emit :T_ARGS_BEGIN };
    ')'        => { emit :T_ARGS_END };
    ','        => { emit :T_COMMA };
    '.'        => { emit :T_DOT };
    string_lit => { emit_notes :string_lit };
    
    '}'        => { emit :T_BINDING_END; fret; };
    
    any => { error :bind_body };
  *|;
  
  binl_body := |*
    c_space;
    
    decl_begin => { fcall decl_body; };
    dstr_begin => { fcall dstr_body; };
    'nil'      => { emit :T_NIL };
    numeric    => { emit :T_NUMERIC };
    constant   => { emit :T_CONSTANT };
    identifier => { emit :T_IDENTIFIER };
    '('        => { emit :T_ARGS_BEGIN; @in_args = true };
    ')'        => { emit :T_ARGS_END;   @in_args = false };
    ','        => { emit :T_COMMA };
    '.'        => { emit :T_DOT };
    string_lit => { emit_notes :string_lit };
    
    c_eol      => { (emit :T_BINDING_END, @ts, @ts; fret;) unless @in_args };
    
    any => { error :binl_body };
  *|;
  
  
}%%
# %
