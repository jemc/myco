
class CodeTools::AST::DeclareFile
  def to_ruby g
    g.add("__cscope__ = Rubinius::ConstantScope.of_sender")
    g.line("")
    implementation.to_ruby(g, "set_myco_file")
  end
end
