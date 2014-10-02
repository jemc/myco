
module Myco
  
  class CodeLoader
    
    class << self
      attr_accessor :drop_rb  # Whether to cache generated ruby code to disk.
      attr_accessor :drop_rbc # Whether to cache rubinius bytecode to disk.
      attr_accessor :precedence # Order of precedence for file types.
    end
    self.drop_rb = false # Do not emit ruby code by default.
    self.drop_rbc = true # Do cache rubinius bytecode by default.
    
    # Use cached rubinius bytecode files if they are up to date.
    # Use Myco files otherwise.
    # Use generated ruby files only when Myco files cannot be found or loaded.
    self.precedence = [:rbc, :myco, :rb]
    
    # Try to resolve the given file path
    # in the current working directory or in the given load paths.
    def self.resolve_file path, load_paths=[]
      tmp_path = File.expand_path(path)
      use_path = File.file?(tmp_path) && tmp_path
      load_paths.each { |load_path|
        break if use_path
        tmp_path = File.expand_path(path, load_path)
        use_path = File.file?(tmp_path) && tmp_path
      }
      
      use_path
    end
    
    # Select a loader and file path for the given path,
    # considering the currently selected order of precedence for file types.
    def self.loader_for_file path, load_paths=[]
      use_path = nil
      use_type = nil
      precedence.each { |type|
        use_type = type
        use_path = (type==:myco) ? path : path+".#{type}"
        use_path = resolve_file(use_path, load_paths)
        break if use_path
      }
      
      raise ArgumentError, "Couldn't resolve file: #{path.inspect} \n" \
                           "in load_paths: #{load_paths.inspect}" \
        unless use_path
      
      loader_for(use_type, use_path)
    end
    
    # Return a loader of the given type with the given arguments
    def self.loader_for type, *args
      case type
      when :myco; MycoLoader.new(*args)
      when :rbc;  BytecodeLoader.new(*args)
      when :rb;   RubyLoader.new(*args)
      else;       raise NotImplementedError
      end
    end
    
    # Load from the given path and load_paths and call
    # under the given ConstantScope, VariableScope, and receiver.
    # If cscope or vscope or receiver are nil, they are pulled from
    # the given call_depth, corresponding to one of the calling frames.
    # 
    def self.load path, load_paths=[], call_depth:1, **kwargs
      loader = loader_for_file(path, load_paths)
      loader.bind_to(call_depth:call_depth+1, **kwargs)
      loader.load
    end
    
    class AbstractLoader
      attr_accessor :filename, :line
      attr_accessor :constant_scope, :variable_scope, :receiver
      
      attr_accessor :string
      attr_accessor :ast
      attr_accessor :generator
      attr_accessor :compiled_code
      attr_accessor :block_environment
      
      def initialize filename, line = 1
        @filename = filename
        @line     = line
      end
      
      def bind_to cscope:nil, vscope:nil, receiver:nil,
                  call_depth:1
        loc = Rubinius::VM.backtrace(call_depth, true).first
        @constant_scope = cscope || loc.constant_scope
        @variable_scope = vscope || loc.variables
        @receiver =     receiver || loc.instance_variable_get(:@receiver)
        
        self
      end
      
      def make_string
        @string = File.read(filename)
      end
      
      def make_ast
        parser = parser_type.new(@filename, @line, [])
        ast = parser.parse_string(@string)
        
        ast = ast_root_type.new(ast) if ast_root_type
        ast.file = filename.to_sym
        ast.variable_scope = @variable_scope
        
        @ast = ast
      end
      
      def make_generator
        g = generator_type.new
        @ast.bytecode(g)
        
        g.close
        g.encode
        
        @generator = g
      end
      
      def make_compiled_code
        code = @generator.package(Rubinius::CompiledCode)
        
        code.scope = @constant_scope
        script = Rubinius::CompiledCode::Script.new(code, @filename, true)
        script.eval_source = @string
        code.scope.script = script
        
        @compiled_code = code
      end
      
      def make_block_environment
        be = Rubinius::BlockEnvironment.new
        be.under_context(@variable_scope, @compiled_code)
        
        @block_environment = be
      end
      
      def compile
        @block_environment  || (
          @compiled_code    || (
            @generator      || (
              @ast          || (
                @string     || (
                make_string    )
              make_ast         )
            make_generator     )
          make_compiled_code   )
        make_block_environment )
      end
      
      def load
        (@block_environment || compile).call_on_instance(@receiver)
      end
    end
    
    class MycoLoader < AbstractLoader
      def ast_root_type
        Myco::ToolSet::AST::EvalExpression
      end
      
      def parser_type
        Myco::ToolSet::Parser
      end
      
      def generator_type
        Myco::ToolSet::Generator
      end
    end
    
    class RubyLoader < AbstractLoader
      def ast_root_type
        Rubinius::ToolSets::Runtime::AST::EvalExpression
      end
      
      def parser_type
        Rubinius::ToolSets::Runtime::Melbourne
      end
      
      def generator_type
        Rubinius::ToolSets::Runtime::Generator
      end
    end
  end
  
end
