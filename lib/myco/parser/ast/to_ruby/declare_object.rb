
class CodeTools::AST::DeclareObject
  def to_ruby g, scope_directive="set_myco_component"
    scoped_body = @body.dup
    if @body.respond_to?(:array)
      cscope_assign = Object.new
      cscope_revert = Object.new
      
      cscope_assign.send(:define_singleton_method, :to_ruby) { |g|
        g.add("__cscope__ = Rubinius::ConstantScope.new(self, __cscope__)")
        g.line("__cscope__.#{scope_directive}")
      }
      cscope_revert.send(:define_singleton_method, :to_ruby) { |g|
        g.add("__cscope__ = __cscope__.parent")
      }
      
      scoped_body.array.unshift(cscope_assign)
      scoped_body.array.push(cscope_revert)
    end
    
    g.add("(")
    g.add("__c__ = ::Myco::Component.new("); g.add(@types); g.add(", self, __FILE__, __LINE__)")
    g.line("__c__.__last__ = __c__.module_eval {"); g.add(scoped_body); g.add("}")
    @create ? g.line("__c__.instance") : g.line("__c__")
    g.add(")")
  end
end
