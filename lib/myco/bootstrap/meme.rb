
module Myco
  module MemeBindable
    def memes
      @memes ||= {}
    end
    
    def declare_meme name, decorations=[], body=nil, &blk
      meme = Meme.new self, name, body, &blk
      
      decorations = decorations.map do |pair|
        decoration, arguments = *pair # TODO: remove workaround for rubinius issue #3114
        decorators = main.categories[:decorators]
        decorators = decorators && decorators.instance
        
        unless decorators.respond_to?(decoration)
          reason = if decorators.nil?
            "#{self} has no [decorators] category."
          else
            "Known decorators in #{decorators}: " \
            "#{decorators.component.memes.keys.inspect}."
          end
          raise KeyError,
            "Unknown decorator for #{self}##{name}: '#{decoration}'. #{reason}" 
        end
        
        [decorators.send(decoration), arguments]
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
    attr_accessor :expose
    
    def to_s
      "#<#{self.class}:#{self.name.to_s}>"
    end
    
    def inspect
      to_s
    end
    
    def initialize target, name, body=nil, &blk
      self.target = target
      self.name   = name
      self.body   = body || blk
      self.cache  = false
      self.expose = true
      
      @caches = {}
    end
    
    def body= value
      case value
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
        @body = Rubinius::BlockEnvironment::AsMethod.new block_env
      else
        raise ArgumentError,
          "Meme body must be a Rubinius::Executable, " \
          "Rubinius::BlockEnvironment or a Proc; got: #{value.inspect}"
      end
      
      @body
    end
    
    def to_proc
      Proc.__from_block__(@body.block_env)
    end
    
    def bind
      return if not @expose
      
      target.extend(MemeBindable) unless target.is_a?(MemeBindable)
      target.memes[@name] = self
      
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
        # if meme.cache.false? || !caches.has_key?(cache_key)
        #   return caches[cache_key]
        # end
        #
        g.push_local 1 # meme
        g.send :cache, 0
        g.send :false?, 0
        g.goto_if_true invoke
        
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
    
    def result *args, &blk
      result_for target.instance, *args, &blk
    end
    
    def result_for obj, *args, &blk
      cache_key = [obj.hash, args.hash, blk.hash]
      if @cache && @caches.has_key?(cache_key)
        return @caches[cache_key]
      end
      
      result = @body.invoke @name, @target, obj, args, blk
      
      @caches[cache_key] = result
    end
    
    def set_result_for obj, result, *args, &blk
      cache_key = [obj.hash, args.hash, blk.hash]
      @caches[cache_key] = result
    end
  end
end
