
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
  
  # TODO: replace with proper import set of functions
  def self.eval_file path, load_paths=nil, get_last=true
    load_paths ||= [File.dirname(Rubinius::VM.backtrace(1).first.file)]
    
    tmp_path = File.expand_path(path)
    use_path = File.file?(tmp_path) && tmp_path
    load_paths.each do |load_path|
      break if use_path
      tmp_path = File.expand_path(path, load_path)
      use_path = File.file?(tmp_path) && tmp_path
    end
    
    raise ArgumentError, "Couldn't resolve file: #{path.inspect} \n" \
                         "in load_paths: #{load_paths.inspect}" \
      unless use_path
    
    file_toplevel = Myco.eval File.read(use_path), nil, use_path
    get_last ? file_toplevel.component.__last__ : file_toplevel.component
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
