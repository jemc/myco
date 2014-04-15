
%%machine lexer; # %

%%{
# %
  id_const = c_upper c_alnum+;
  
  main := |*
    id_const => { p [:id_const, text.to_sym]; };
    
    # Unexpected character
    any => { p [:"???", text] };
  *|;
}%%
# %
