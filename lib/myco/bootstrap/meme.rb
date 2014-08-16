
module Myco
  class Meme
    attr_accessor :target
    attr_accessor :name
    attr_accessor :body
    attr_accessor :memoize
    
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
      
      @memos  = {} # TODO: use weak map to avoid consuming endless memory
    end
    
    def bind
      meme = self
      target.memes[@name] = meme
      
      target.send :define_method, @name do |*args, &blk|
        meme.call_on(self, *args, &blk)
      end
    end
    
    def call_on obj, *args, &blk
      memo_key = [obj.hash, args.hash, blk.hash]
      if @memoize && result = @memos[memo_key]
        return result
      end
      
      result = if @body.is_a? Rubinius::Executable
        @body.invoke @name, @target, obj, args, blk
      elsif @body.respond_to? :call
        @body.call *args, &blk
      else
        raise "The body of #{self} is not executable"
      end
      
      @memos[memo_key] = result
    end
    
    def result *args, &blk
      call_on target.instance, *args, &blk
    end
  end
end
