
require_relative 'myco_module_scope'

class CodeTools::AST::DeclareFileScope
  def to_ruby_scope_directive g
    g.line("__cscope__.set_myco_file")
  end
end

class CodeTools::AST::DeclareFile
  def to_ruby g
    g.add("__cscope__ = Rubinius::ConstantScope.of_sender")
    g.line("")
    implementation.to_ruby(g)
  end
end
