
module Myco
  
  # TODO: deprecate with proper import set of functions
  def self.eval(string, call_depth:1)
    loader = Myco::CodeLoader::MycoLoader.new("(eval)")
    loader.bind_to(call_depth: call_depth + 1)
    loader.string = string
    loader.load
  end
  
  # TODO: deprecate with proper import set of functions
  def self.eval_file path, load_paths=nil, get_last=true, scope=nil
    load_paths ||= [File.dirname(Rubinius::VM.backtrace(1).first.file)]
    file_toplevel = CodeLoader.load(path, load_paths, cscope:scope, call_depth:1)
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
