
Rubinius::ToolSets.create :Myco do
  Rubinius::CodeLoader.require_compiled "rubinius/compiler"
  Rubinius::CodeLoader.require_compiled "rubinius/ast"
  Rubinius::CodeLoader.require_compiled "rubinius/processor"
  Rubinius::CodeLoader.require_compiled "rubinius/melbourne"
end

module Myco
  ToolSet = Rubinius::ToolSets::Myco
end
