
class CodeTools::AST::LocalVariableAccessAmbiguous
  def to_ruby g
    if g.var_scope_has_local?(@name)
      g.add(@name.to_s)
    else
      g.add("self")
      
      if g.easy_ident?(@name)
        g.add(".#{@name}")
      else
        g.add(".__send__(#{name.inspect})")
      end
    end
  end
end
