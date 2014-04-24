
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum*;
  identifier = c_lower c_alnum*;
  
  numeric    = '-'? [0-9]+ ('.' [0-9]+)?;
  
  
  # Foo,Bar,Baz
  #
  constant_list = (
    zlen           % { @marks[:constant_list] = [@p] }
    constant       % {(@marks[:constant_list] << @p) << :T_CONSTANT }
    (
      c_space*     % { @marks[:constant_list] << @p }
      ','          % {(@marks[:constant_list] << @p) << :T_COMMA }
      c_space_nl*  % { @marks[:constant_list] << @p }
      constant     % {(@marks[:constant_list] << @p) << :T_CONSTANT }
    )*
  );
  
  # Foo < 
  #
  cdefn_begin = (
    constant  % { grab :defn_constant }
    c_space*  % { mark :space }
    '<'       % { grab :defn_caret, kram(:space) }
    c_space*  % { mark :space }
  ) % {
    stuff :T_CONSTANT, :defn_constant
    stuff :T_DEFINE,   :defn_caret
  };
  
  # Object { ... }
  #
  decl_begin = (
    cdefn_begin?
    constant_list
    c_space_nl*  % { mark :space }
    '{'          % { grab :brace, kram(:space) }
  ) % {
    @marks[:constant_list].each_slice(3) { |a,b,c| emit c,a,b if a&&b&&c }
    stuff :T_DECLARE_BEGIN, :brace
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
    @marks[:constant_list].each_slice(3) { |a,b,c| emit c,a,b if a&&b&&c }
    
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
  
  # Foo: { ... }
  #
  cbind_begin = (
    constant                    % { grab :constant }
    (c_space* ':' c_space_nl*)  % { mark :space }
    '{'                         % { grab :brace, kram(:space) }
  ) % {
    stuff :T_CONSTANT,      :constant
    stuff :T_BINDING_BEGIN, :brace
  };
  
  # Foo: ...
  #
  cbinl_begin = (
    constant                    % { grab :constant }
    (c_space* ':' c_space*)
    ^(c_space_nl|'{')           % { fhold; grab :brace, @p, @p }
  ) % {
    stuff :T_CONSTANT,      :constant
    stuff :T_BINDING_BEGIN, :brace
  };
  
  # |a, b, *args, c:4, d:5, **kwargs|
  #
  param_list = (
    zlen               % { @marks[:param_list] = [@p] }
    '|'                % {(@marks[:param_list] << @p) << :T_PARAMS_BEGIN }
    c_space_nl*        % { @marks[:param_list] << @p }
    identifier         % {(@marks[:param_list] << @p) << :T_IDENTIFIER }
    c_space*           % { @marks[:param_list] << @p }
    (
      ','              % {(@marks[:param_list] << @p) << :T_COMMA }
      c_space_nl*      % { @marks[:param_list] << @p }
      identifier       % {(@marks[:param_list] << @p) << :T_IDENTIFIER }
      c_space*         % { @marks[:param_list] << @p }
    )*
    '|'                % {(@marks[:param_list] << @p) << :T_PARAMS_END }
  );
  
  # foo: { ... }
  #
  bind_begin = (
    identifier                  % { grab :identifier }
    (c_space* ':' c_space_nl*)
    param_list?
    (c_space_nl*)               % { mark :space }
    '{'                         % { grab :brace, kram(:space) }
  ) % {
    stuff :T_IDENTIFIER,    :identifier
    (@marks[:param_list] || []).each_slice(3) { |a,b,c| emit c,a,b if a&&b&&c }
    stuff :T_BINDING_BEGIN, :brace
  };
  
  # foo: ...
  #
  binl_begin = (
    identifier                  % { grab :identifier }
    (c_space* ':' c_space_nl*)
    param_list?
    (c_space_nl*)               % { mark :space }
    ^(c_space_nl|'{'|'|')       % { fhold; grab :brace, @p, @p }
  ) % {
    stuff :T_IDENTIFIER,    :identifier
    (@marks[:param_list] || []).each_slice(3) { |a,b,c| emit c,a,b if a&&b&&c }
    stuff :T_BINDING_BEGIN, :brace
  };
  
  ##
  # Top level machine
  
  main := |*
    c_space_nl;
    
    cbind_begin => { fcall bind_body; };
    cbinl_begin => { fcall binl_body; };
    
    decl_begin  => { fcall decl_body; };
    dstr_begin  => { fcall dstr_body; };
    constant    => { emit :T_CONSTANT };
    
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
    
    cbind_begin => { fcall bind_body; };
    cbinl_begin => { fcall binl_body; };
    
    bind_begin  => { fcall bind_body; };
    binl_begin  => { fcall binl_body; };
    
    '}' => { emit :T_DECLARE_END; fret; };
    
    any => { error :decl_body };
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
  # Binding body machines
  
  bind_body := |*
    c_space_nl;
    
    decl_begin => { fcall decl_body; };
    dstr_begin => { fcall dstr_body; };
    'nil'      => { emit :T_NIL };
    numeric    => { emit :T_NUMERIC };
    constant   => { emit :T_CONSTANT };
    identifier => { emit :T_IDENTIFIER };
    
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
    
    c_eol      => { emit :T_BINDING_END, @ts, @ts; fret; };
    
    any => { error :binl_body };
  *|;
  
}%%
# %
