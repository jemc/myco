
class CodeTools::AST::SplatValue
  def to_ruby g
    if @value.is_a?(self.class)
      @value.to_ruby(g)
    else
      g.add("*")
      @value.to_ruby(g)
    end
  end
end

module CodeTools::AST
  class CollectSplat
    def to_ruby g
      # TODO
    end
  end
end

module CodeTools::AST
  class ConcatArgs
    def to_ruby g
      # TODO
    end
  end
end

class CodeTools::AST::PushArgs
  def to_ruby g
    # TODO
  end
end
