
class CodeTools::AST::MycoModuleScope
  def to_ruby_scope_directive g
    raise NotImplementedError
  end
  
  def to_ruby g
    if @body.respond_to?(:array)
      scoped_body = @body.dup
      cscope_assign = Object.new
      cscope_revert = Object.new
      cscope_directive = Proc.new { |g| to_ruby_scope_directive(g) }
      
      cscope_assign.send(:define_singleton_method, :to_ruby) { |g|
        g.add("__cscope__ = Rubinius::ConstantScope.new(self, __cscope__)")
        cscope_directive.call(g)
      }
      cscope_revert.send(:define_singleton_method, :to_ruby) { |g|
        g.add("__cscope__ = __cscope__.parent")
      }
      
      scoped_body.array.unshift(cscope_assign)
      scoped_body.array.push(cscope_revert)
      g.add(scoped_body)
    else
      g.add(@body)
    end
  end
end
