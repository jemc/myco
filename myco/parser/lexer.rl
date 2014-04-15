
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum+;
  identifier = c_lower c_alnum+;
  
  object_begin = '{';
  object_end   = '}';
  
  
  main := |*
    c_space_nl;
    constant => { emit :T_CONSTANT; fcall at_constant; };
    
    any => { error :main };
  *|;
  
  at_constant := |*
    c_space_nl;
    object_begin => { emit :T_OBJECT_BEGIN; fgoto decl_obj_body; };
    
    any => { error :at_constant };
  *|;
  
  at_identifier := |*
    c_space_nl;
    (':' c_space* '{')         => { emit :T_BINDING_BEGIN, @te-1, @te;      fgoto binding_body; };
    (':' c_space* ^c_space_nl) => { emit :T_BINDING_BEGIN, @te, @te; fhold; fgoto binding_body_inline; };
    
    any => { error :at_identifier };
  *|;
  
  decl_obj_body := |*
    c_space_nl;
    
    constant   => { emit :T_CONSTANT;   fcall at_constant;   };
    identifier => { emit :T_IDENTIFIER; fcall at_identifier; };
    
    object_end => { emit :T_OBJECT_END; fret; };
    
    any => { error :decl_obj_body };
  *|;
  
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
