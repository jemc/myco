
class CodeTools::AST::DeclareMeme
  def to_ruby g
    g.with_nested_var_scope(body_implementation) {
      g.var_scope_declare_locals(@arguments.names)
      
      g.add("declare_meme(")
      g.add("#{@name.inspect}, ")
      g.add(@decorations); g.add(", nil, ::Myco.cscope.dup)")
      g.add(" { ");
        g.add(@arguments); g.add(" ")
        g.add(@body);
      g.add("}")
    }
  end
end
