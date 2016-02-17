
module Myco
  # In Myco, try to always use Myco.add_method instead of Rubinius.add_method
  # to bypass all of the Ruby-specific logic therein.
  
  def self.add_method mod, name, executable, cscope
    mod.method_table.store(name, nil, executable, cscope, 0, :public)
    Rubinius::VM.reset_method_cache(mod, name)
  end
  
  # TODO: override Module#define_method in Component to use this?
  # TODO: override Module#thunk_method in Component to use this?
  # TODO: override Module#dynamic_method in Component to use this?
  
  # Use instead of Module#thunk_method
  def self.add_thunk_method mod, name, value
    add_method(mod, name, Rubinius::Thunk.new(value), nil)
  end
  
  # Use instead of Module#dynamic_method
  def self.add_dynamic_method mod, name, file="(dynamic)", line=1
    g = Rubinius::ToolSets::Runtime::Generator.new
    g.name = name.to_sym
    g.file = file.to_sym
    g.set_line Integer(line)

    yield g

    g.close
    g.use_detected
    g.encode

    code = g.package Rubinius::CompiledCode
    cscope = Rubinius::ConstantScope.new(mod, Rubinius::ConstantScope.new(Myco))

    add_method(mod, name, code, cscope)
  end
end
