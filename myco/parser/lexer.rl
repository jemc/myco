
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum+;
  identifier = c_lower c_alnum+;
  
  
  ##
  # Top level machine
  
  main := |*
    c_space_nl;
    constant => { emit :T_CONSTANT; fcall at_decl_constant; };
    
    any => { error :main };
  *|;
  
  ##
  # Declarative expression machines, grouped by what they begin with 
  
  at_decl_constant := |*
    c_space_nl;
    '{' => { emit :T_DECLARE_BEGIN; fgoto decl_body; };
    
    any => { error :at_decl_constant };
  *|;
  
  at_decl_identifier := |*
    c_space_nl;
    (':' c_space* '{')         => { emit :T_BINDING_BEGIN, @te-1, @te;      fgoto binding_body; };
    (':' c_space* ^c_space_nl) => { emit :T_BINDING_BEGIN, @te, @te; fhold; fgoto binding_body_inline; };
    
    any => { error :at_decl_identifier };
  *|;
  
  ##
  # Declarative body machines
  
  decl_body := |*
    c_space_nl;
    
    constant   => { emit :T_CONSTANT;   fcall at_decl_constant;   };
    identifier => { emit :T_IDENTIFIER; fcall at_decl_identifier; };
    
    '}' => { emit :T_DECLARE_END; fret; };
    
    any => { error :decl_body };
  *|;
  
  ##
  # Binding body machines
  
  binding_body := |*
    c_space_nl;
    identifier => { emit :T_IDENTIFIER; };
    '}'        => { emit :T_BINDING_END; fret; };
    
    any => { error :binding_body };
  *|;
  
  binding_body_inline := |*
    c_space;
    identifier => { emit :T_IDENTIFIER; };
    c_nl       => { emit :T_BINDING_END, @ts, @ts; fret; };
    
    any => { error :binding_body_inline };
  *|;
  
}%%
# %
