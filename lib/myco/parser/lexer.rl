
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum*;
  identifier = c_lower c_alnum*;
  
  numeric    = '-'? [0-9]+ ('.' [0-9]+)?;
  
  
  # Foo,Bar,Baz
  #
  constant_list = (
    constant       % { @marks[:constant_list] = [@ts, @p] }
    (
      c_space*     % { @marks[:constant_list] << @p }
      ','          % { @marks[:constant_list] << @p }
      c_space_nl*  % { @marks[:constant_list] << @p }
      constant     % { @marks[:constant_list] << @p }
    )*
  );
  
  # Object { ... }
  #
  decl_begin = (
    constant_list
    c_space_nl*  % { mark :space }
    '{'          % { grab :brace, kram(:space) }
  ) % {
    @marks[:constant_list].each_slice(4) do |a,b,c,d|
      emit :T_CONSTANT, a, b if a && b
      emit :T_COMMA,    c, d if c && d
    end
    stuff :T_DECLARE_BEGIN, :brace
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
  
  # foo: { ... }
  #
  bind_begin = (
    identifier                  % { grab :identifier }
    (c_space* ':' c_space_nl*)  % { mark :space }
    '{'                         % { grab :brace, kram(:space) }
  ) % {
    stuff :T_IDENTIFIER,    :identifier
    stuff :T_BINDING_BEGIN, :brace
  };
  
  # foo: ...
  #
  binl_begin = (
    identifier                  % { grab :identifier }
    (c_space* ':' c_space*)
    ^(c_space_nl|'{')           % { fhold; grab :brace, @p, @p }
  ) % {
    stuff :T_IDENTIFIER,    :identifier
    stuff :T_BINDING_BEGIN, :brace
  };
  
  ##
  # Top level machine
  
  main := |*
    c_space_nl;
    
    cbind_begin => { fcall bind_body; };
    cbinl_begin => { fcall binl_body; };
    
    decl_begin  => { fcall decl_body; };
    constant    => { emit :T_CONSTANT };
    
    c_eof;
    any => { error :main };
  *|;
  
  ##
  # Declarative body machine
  
  decl_body := |*
    c_space_nl;
    
    decl_begin  => { fcall decl_body; };
    constant    => { emit :T_CONSTANT };
    
    cbind_begin => { fcall bind_body; };
    cbinl_begin => { fcall binl_body; };
    
    bind_begin  => { fcall bind_body; };
    binl_begin  => { fcall binl_body; };
    
    '}' => { emit :T_DECLARE_END; fret; };
    
    any => { error :decl_body };
  *|;
  
  ##
  # Binding body machines
  
  bind_body := |*
    c_space_nl;
    
    decl_begin => { fcall decl_body; };
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
    'nil'      => { emit :T_NIL };
    numeric    => { emit :T_NUMERIC };
    constant   => { emit :T_CONSTANT };
    identifier => { emit :T_IDENTIFIER };
    
    c_eol      => { emit :T_BINDING_END, @ts, @ts; fret; };
    
    any => { error :binl_body };
  *|;
  
}%%
# %
