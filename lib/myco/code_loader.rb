
module Myco
  
  class CodeLoader
    
    class << self
      attr_accessor :emit_rb  # Whether to cache generated ruby code to disk.
      attr_accessor :emit_rbc # Whether to cache rubinius bytecode to disk.
      attr_accessor :precedence # Order of precedence for file types.
    end
    self.emit_rb = false # Do not emit ruby code by default.
    self.emit_rbc = true # Do cache rubinius bytecode by default.
    
    # Use cached rubinius bytecode files if they are up to date.
    # Use Myco files otherwise.
    # Use generated ruby files only when Myco files cannot be found or loaded.
    self.precedence = [:rbc, :myco, :rb]
    
    # TODO: a more elegant solution than env vars
    # Emit ruby if env var indicates
    # Load from ruby exclusively if env var indicates
    self.emit_rb    = true    if ENV['MYCO_TO_RUBY'] == 'PRE'
    self.precedence = [:myco] if ENV['MYCO_TO_RUBY'] == 'PRE'
    
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
      use_path = resolve_file(path, load_paths)
      
      raise ArgumentError, "Couldn't resolve file: #{path.inspect} \n" \
                           "in load_paths: #{load_paths.inspect}" \
        unless use_path
      
      # Try to find an implementation with higher precedence than :myco
      # With a file that has been modified at least as recently as
      # the resolved file in use_path.
      ref_mtime = File.mtime(use_path)
      precedence.each { |type|
        begin
          if type==:myco
            return loader_for(type, use_path)
          else
            alt_path = use_path + ".#{type}"
            if File.file?(alt_path) && (File.mtime(alt_path) >= ref_mtime)
              return loader_for(type, alt_path)
            end
          end
        rescue NotImplementedError # Skip loader if not implemented
        end
      }
      
      return nil
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
      loader.compile
      loader.emit_rb!  if self.emit_rb  and !loader.is_rbc? and !loader.is_rb?
      loader.emit_rbc! if self.emit_rbc and !loader.is_rbc?
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
        @string || make_string
        
        parser = parser_type.new(@filename, @line, [])
        ast = parser.parse_string(@string)
        
        ast = ast_root_type.new(ast) if ast_root_type
        ast.file = filename.to_sym
        ast.variable_scope = @variable_scope
        
        @ast = ast
      end
      
      def make_generator
        @ast || make_ast
        
        g = generator_type.new
        @ast.bytecode(g)
        
        g.close
        g.encode
        
        @generator = g
      end
      
      def make_compiled_code
        @generator || make_generator
        
        code = @generator.package(Rubinius::CompiledCode)
        
        @compiled_code = code
      end
      
      def make_block_environment
        @compiled_code || make_compiled_code
        code = @compiled_code
        
        code.scope = @constant_scope
        script = Rubinius::CompiledCode::Script.new(code, @filename, true)
        script.eval_source = @string
        code.scope.script = script
        
        be = Rubinius::BlockEnvironment.new
        be.under_context(@variable_scope, code)
        
        @block_environment = be
      end
      
      def compile
        @block_environment || make_block_environment
      end
      
      def load
        compile
        @block_environment.call_on_instance(@receiver)
      end
      
      def emit_rb! filename=nil
        filename ||= myco_filename.concat('.rb')
        
        mkdir_p(File.dirname(filename))
        File.open(filename, "w+") { |file| file.write(@ast.to_ruby_code) }
      end
      
      def emit_rbc! filename=nil
        filename ||= myco_filename.concat('.rbc')
        mkdir_p(File.dirname(filename))
        
        compiled_file_type.dump(
          @compiled_code, filename, Rubinius::Signature, 0
        )
      end
      
      def is_rb?;  false end
      def is_rbc?; false end
      
      private
      
      # Return @filename, stripped of any .rbc or .rb file extension
      def myco_filename
        @filename.sub(/\.rbc?$/, '')
      end
      
      def mkdir_p dir
        # TODO: do manually, without depending on FileUtils
        require 'fileutils'
        FileUtils.mkdir_p(dir)
      end
    end
    
    class MycoLoader < AbstractLoader
      def initialize *args
        # TODO: a more elegant solution than env vars
        raise NotImplementedError if ENV['MYCO_TO_RUBY'] == 'POST'
        super
      end
      
      def ast_root_type
        Myco::ToolSet::AST::EvalExpression
      end
      
      def parser_type
        Myco::ToolSet::Parser
      end
      
      def generator_type
        Myco::ToolSet::Generator
      end
      
      def compiled_file_type
        Myco::ToolSet::CompiledFile
      end
    end
    
    class RubyLoader < AbstractLoader
      def is_rb?; true end
      
      def initialize *args
        super *args
      end
      
      def ast_root_type
        Rubinius::ToolSets::Runtime::AST::EvalExpression
      end
      
      def parser_type
        Rubinius::ToolSets::Runtime::Melbourne
      end
      
      def generator_type
        Rubinius::ToolSets::Runtime::Generator
      end
      
      def compiled_file_type
        Rubinius::ToolSets::Runtime::CompiledFile
      end
    end
    
    class BytecodeLoader < AbstractLoader
      def is_rbc?; true end
      
      def initialize *args
        # TODO: a more elegant solution than env vars
        raise NotImplementedError if ENV['MYCO_TO_RUBY'] == 'POST'
        super
      end
      
      def make_compiled_code
        @compiled_code = primitive_load_file(@filename, Rubinius::Signature, 0)
      end
      
      private
      
      def primitive_load_file(path, signature, version)
        Rubinius.primitive :compiledfile_load
        raise Rubinius::InvalidRBC, "Invalid RBC file: #{path}"
      end
    end
  end
  
end
