
module Myco
  module MemeBindable
    def memes
      @memes ||= {}
    end
    
    def declare_meme name, decorations=[], body=nil, cscope=nil, &blk
      meme = Meme.new self, name
      if cscope && blk
        body = blk.block.dup
        blk = nil
        body.instance_variable_set(:@constant_scope, cscope)
      end
      meme.body = body || blk
      
      decorations = decorations.map do |decoration, arguments|
        decorators = main.category(:decorators)
        decorators = decorators && decorators.instance
        
        unless Rubinius::Type.object_respond_to?(decorators, decoration)
          reason = if !decorators
            "#{self} has no [decorators] category."
          else
            "Known decorators in #{decorators}: " \
            "#{decorators.component.memes.keys.inspect}."
          end
          raise KeyError,
            "Unknown decorator for #{self}##{name}: '#{decoration}'. #{reason}" 
        end
        
        [decorators.__send__(decoration), arguments]
      end
      decorations.each { |deco, args| deco.transforms.apply meme, *args }
      decorations.each { |deco, args| deco.apply meme, *args }
      
      meme.bind
      
      meme
    end
  end
  
  class Meme
    attr_accessor :target
    attr_accessor :name
    attr_accessor :body
    attr_accessor :cache
    attr_accessor :var
    attr_accessor :expose
    attr_accessor :setter
    attr_accessor :getter
    
    attr_reader :metadata
    
    def to_s
      "#<#{self.class}:#{self.name.to_s}>"
    end
    
    def inspect
      to_s
    end
    
    def initialize target, name, body=nil, &blk
      self.target = target
      self.name   = name
      self.body   = body if body
      self.body   = blk  if blk
      self.cache  = false
      self.var    = false
      self.expose = true
      
      @metadata = {}
      
      @caches = {}
    end
    
    def body= value
      case value
      when Rubinius::BlockEnvironment::AsMethod
        @body = value
      when Rubinius::Thunk
        @body = value
      when Rubinius::Executable
        @body = value
        @body.scope.set_myco_meme self
      when Rubinius::BlockEnvironment
        block_env = value
        block_env.change_name name
        block_env.constant_scope.set_myco_meme self
        @body = Rubinius::BlockEnvironment::AsMethod.new block_env
      when Proc
        block_env = value.block.dup
        block_env.change_name name
        block_env.constant_scope.set_myco_meme self \
          unless block_env.constant_scope.myco_meme
        @body = Rubinius::BlockEnvironment::AsMethod.new block_env
      else
        raise ArgumentError,
          "Meme body must be a Rubinius::Executable, " \
          "Rubinius::BlockEnvironment or a Proc; got: #{value.inspect}"
      end
      
      @effective_body = @body
      
      bind if @bound
      @body
    end
    
    def target= value
      @target = value
      @target.extend(MemeBindable) unless @target.is_a?(MemeBindable)
      bind if @bound
      @target
    end
    
    def cache= value
      @cache = value
      bind if @bound
      @cache
    end
    
    def var= value
      @var = value
      bind if @bound
      @var
    end
    
    def to_proc
      Proc.__from_block__(@body.block_env)
    end
    
    def bind
      @bound = true
      return if not @expose
      
      @target.memes[@name] = self
      
      # TODO: consider removing
      @target.include(::Myco::PrimitiveInstanceMethods) unless @target < ::Myco::PrimitiveInstanceMethods
      
      if @var
        bind_var_getter
        bind_var_setter
        @effective_body = @target.instance_method(@name).executable
      elsif @getter
        bind_var_getter
        @effective_body = @target.instance_method(@name).executable
      elsif @setter
        bind_var_setter
        @effective_body = @target.instance_method(@name).executable
      elsif @cache
        bind_cache_method
        @effective_body = @target.instance_method(@name).executable
      else
        Myco.add_method(@target, @name, @body)
      end
    end
    
    def result *args, &blk
      result_for target.instance, *args, &blk
    end
    
    def result_for obj, *args, &blk
      result = @effective_body.invoke @name, @target, obj, args, blk
    end
    
    def set_result_for obj, result, *args, &blk
      raise "Can't set_result_for this Meme" unless @cache
      cache_key = [obj.hash, args.hash, blk.hash]
      @caches[cache_key] = result
    end
    
  private
    
    def bind_cache_method
      ##
      # This dynamic method is nearly the same as Meme#result_for
      # (but written from the perspective of the receiver)
      # implemented in bytecode to avoid forwarding to another method
      # on the call stack.
      # TODO: move this bytecode generation to a helper method 
      meme = self
      
      target.dynamic_method @name, '(myco_internal)' do |g|
        g.splat_index = 0 # *args
        
        invoke = g.new_label
        ret    = g.new_label
        
        ##
        # meme = <this meme>
        #
        g.push_literal meme
        g.set_local 1 # meme
        g.pop
        
        ##
        # caches = <this meme's @caches>
        #
        g.push_literal @caches
        g.set_local 2 # caches
        g.pop
        
        ##
        # cache_key = [obj.hash, args.hash, blk.hash]
        #
          g.push_self;     g.send :hash, 0
          g.push_local 0;  g.send :hash, 0 # args
          g.push_block;    g.send :hash, 0
        g.make_array 3
        g.set_local 3 # cache_key
        g.pop
        
        ##
        # if caches.has_key?(cache_key)
        #   return caches[cache_key]
        # end
        #
        g.push_local 2 # caches
          g.push_local 3 # cache_key
        g.send :has_key?, 1
        g.goto_if_false invoke
        
        g.push_local 2 # caches
          g.push_local 3 # cache_key
        g.send :[], 1
        g.goto ret
        
        ##
        # result = meme.body.invoke meme.name, @target, obj, args, blk
        #
        invoke.set!
        
        g.push_local 1 # meme
        g.send :body, 0
          g.push_local 1; g.send :name, 0   # meme.name
          g.push_local 1; g.send :target, 0 # meme.target
          g.push_self
          g.push_local 0 # args
          g.push_block
        g.send :invoke, 5
        g.set_local 4 # result
        g.pop
        
        ##
        # return (caches[cache_key] = result)
        #
        g.push_local 2 # caches
          g.push_local 3 # cache_key
          g.push_local 4 # result
        g.send :[]=, 2
        
        ret.set!
        g.ret
      end
    end
    
    def bind_var_getter
      # TODO: move this bytecode generation to a helper method 
      meme = self
      
      target.dynamic_method @name, '(myco_internal)' do |g|
        get = g.new_label
        ret = g.new_label
        
        ##
        # meme = <this meme>
        #
        g.push_literal meme
        g.set_local 1 # meme
        g.pop
        
        ##
        # if __ivar_defined__(#{name})
        #   @#{name} = meme.body.invoke meme.name, @target, obj, [], nil
        # end
        # return @#{name}
        #
        g.push_self
        g.push_literal(:"@#{@name}")
        g.send(:__ivar_defined__, 1)
        g.goto_if_true(get)
        
        g.push_local 1 # meme
        g.send :body, 0
          g.push_local 1; g.send :name, 0   # meme.name
          g.push_local 1; g.send :target, 0 # meme.target
          g.push_self
          g.make_array 0
          g.push_nil
        g.send :invoke, 5
        g.set_ivar(:"@#{@name}")
        
        g.goto(ret)
        
        get.set!
        g.push_ivar(:"@#{@name}")
        
        ret.set!
        
        # If this meme has a getter defined, use it
        if self.getter
          g.push_self
          g.push_local(1) # meme
          g.send(:getter, 0)
          g.rotate(3)
          g.send(:call_on_object, 2)
        end
        
        g.ret
      end
    end
    
    def bind_var_setter
      # TODO: move this bytecode generation to a helper method 
      meme = self
      
      # TODO: move this bytecode generation to a helper method 
      target.dynamic_method :"#{@name}=", '(myco_internal)' do |g|
        g.total_args = 1
        g.local_count = 1
        
        g.push_local 0 # value
        
        # If this meme has a setter defined, use it
        if meme.setter
          g.push_self
          g.push_literal(meme)
          g.send(:setter, 0)
          g.rotate(3)
          g.send(:call_on_object, 2)
        end
        
        g.set_ivar(:"@#{@name}")
        
        g.ret
      end
    end
    
  end
end
