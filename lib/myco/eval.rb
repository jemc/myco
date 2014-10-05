
module Myco
  
  # Most of method is stolen from Rubinius implementation of Kernel#eval
  # TODO: remove in favor of CodeLoader
  def self.eval(string, scope=nil, filename=nil, lineno=nil, type=:myco)
    string = StringValue(string)
    filename = StringValue(filename) if filename
    lineno = Rubinius::Type.coerce_to lineno, Fixnum, :to_i if lineno
    lineno = 1 if filename && !lineno
    
    binding = ::Binding.setup(Rubinius::VariableScope.of_sender,
                              Rubinius::CompiledCode.of_sender,
                              (scope||Rubinius::ConstantScope.of_sender),
                              self)
    
    filename ||= "(eval)"
    
    lineno ||= binding.line_number
    
    existing_scope = binding.constant_scope
    binding.constant_scope = existing_scope.dup
    
    compiler_class = case type
    when :myco; Myco::ToolSet::Compiler
    when :ruby; Rubinius::ToolSets::Runtime::Compiler
    else; raise NotImplementedError
    end
    
    be = compiler_class.construct_block string, binding, filename, lineno
    
    result = be.call_on_instance(binding.self)
    binding.constant_scope = existing_scope
    result
  end
  
  # TODO: deprecate with proper import set of functions
  def self.eval_file path, load_paths=nil, get_last=true, scope=nil
    load_paths ||= [File.dirname(Rubinius::VM.backtrace(1).first.file)]
    file_toplevel = CodeLoader.load(path, load_paths, cscope:scope, call_depth:2)
    get_last ? file_toplevel.component.__last__ : file_toplevel.component
  end
  
  def self.file_to_ruby use_path
    parser = Myco::ToolSet::Parser.new(use_path, 1, [])
    ast = parser.parse_string File.read(use_path)
    ast.to_ruby_code
  end
  
  def self.rescue
    begin
      yield
    rescue Exception=>e
      unless e.is_a? SystemExit
        puts e.awesome_backtrace.show
        puts e.awesome_backtrace.first_color + e.message + "\033[0m"
        puts
        exit(1)
      end
    end
  end
end
