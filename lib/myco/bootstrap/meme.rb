
module Myco
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
      @target = target
      @name   = name
      @body   = body
      
      if body
        raise TypeError, "Meme body must be a Rubinius::Executable" \
          unless body.is_a? Rubinius::Executable
        @body = body
      elsif blk
        block_env = blk.block.dup
        block_env.change_name name
        @body = Rubinius::BlockEnvironment::AsMethod.new block_env
        blk = blk.dup
        blk.lambda_style!
      else
        raise ArgumentError, "Meme must be passed a body or block argument"
      end
      
      @caches = {}
      
      @expose = true
    end
    
    def bind
      return if not @expose
      
      meme = self
      target.memes[@name] = meme
      
      ##
      # Make the forwarding method as streamlined as possible
      # by defining with bytecode instead of using define_method
      # TODO: move this bytecode generation to a helper method 
      target.dynamic_method @name do |g|
        g.splat_index = 0 # *args
        
        ##
        # meme.result_for(self, *args, &block)
        
        g.push_literal meme
          g.push_self
          g.push_local 0 # *args
          g.push_block
        g.send_with_splat :result_for, 1
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
