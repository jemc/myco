
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum+;
  identifier = c_lower c_alnum+;
  
  object_begin = '{';
  object_end   = '}';
  
  binding_asgn = ':';
  
  binding_begin = '{';
  binding_end   = '}';
  
  
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
    binding_end => { emit :T_BINDING_END; fret; };
    
    any => { error :binding_body };
  *|;
  
  binding_body_inline := |*
    c_space;
    identifier => { emit :T_IDENTIFIER; };
    c_nl => { emit :T_BINDING_END, @ts, @ts; fret; };
    
    any => { error :binding_body_inline };
  *|;
  
  at_constant := |*
    c_space_nl;
    object_begin => { emit :T_OBJECT_BEGIN; fgoto decl_obj_body; };
    
    any => { error :at_constant };
  *|;
  
  at_identifier := |*
    c_space_nl;
    binding_asgn => { emit :T_BINDING_ASGN; fgoto at_binding_asgn; };
    
    any => { error :at_identifier };
  *|;
  
  at_binding_asgn := |*
    c_space_nl;
    binding_begin => { emit :T_BINDING_BEGIN;           fgoto binding_body; };
    any    => { fhold; emit :T_BINDING_BEGIN, @ts, @ts; fgoto binding_body_inline; };
  *|;
  
  
  main := |*
    c_space_nl;
    constant => { emit :T_CONSTANT; fcall at_constant; };
    
    any => { error :main };
  *|;
}%%
# %
