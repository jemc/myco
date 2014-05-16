
module Myco
  
  # Stolen from Kernel#eval with one crucial difference - Compiler class
  def self.eval(string, binding=nil, filename=nil, lineno=nil)
    string = StringValue(string)
    filename = StringValue(filename) if filename
    lineno = Rubinius::Type.coerce_to lineno, Fixnum, :to_i if lineno
    lineno = 1 if filename && !lineno
    
    if binding
      binding = Rubinius::Type.coerce_to_binding binding
      filename ||= binding.constant_scope.active_path
    else
      binding = ::Binding.setup(Rubinius::VariableScope.of_sender,
                                Rubinius::CompiledCode.of_sender,
                                Rubinius::ConstantScope.of_sender,
                                self)
      
      filename ||= "(eval)"
    end
    
    lineno ||= binding.line_number
    
    existing_scope = binding.constant_scope
    binding.constant_scope = existing_scope.dup
    
    c = Myco::ToolSet::Compiler
    be = c.construct_block string, binding, filename, lineno
    
    result = be.call_on_instance(binding.self)
    binding.constant_scope = existing_scope
    result
  end
  
end
