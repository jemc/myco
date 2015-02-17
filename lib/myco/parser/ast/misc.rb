
module CodeTools::AST
  
  # These builder methods are copied directly from rubinius-processor
  # TODO: remove and Myco-ize all dependencies on rubinius-processor and rubinius-ast
  module BuilderMethods
    def colon2 line, outer, name
      if outer
        if outer.kind_of? ConstantAccess and
           outer.name == :Rubinius
          case name
          when :Type
            TypeConstant.new line
          when :Mirror
            MirrorConstant.new line
          else
            ScopedConstant.new line, outer, name
          end
        else
          ScopedConstant.new line, outer, name
        end
      else
        ConstantAccess.new line, name
      end
    end
    
    def colon3 line, name
      ToplevelConstant.new line, name
    end
    
    def const line, name
      ConstantAccess.new line, name
    end
    
    def lit line, sym
      SymbolLiteral.new line, sym
    end
    
    def args line, required, optional, splat, post, kwargs, kwrest, block
      Parameters.new line, required, optional, splat, post, kwargs, kwrest, block
    end
    
    def self line
      Self.new line
    end
    
    def block line, array
      Block.new line, array
    end
    
    def str line, str
      StringLiteral.new line, str
    end
    
    def splat line, expr
      SplatValue.new line, expr
    end
    
    def block_pass line, arguments, body
      BlockPass19.new line, arguments, body
    end
    
    def evstr line, value
      if value
        ToString.new line, value
      else
        StringLiteral.new line, ""
      end
    end
    
    def dsym line, str, array
      DynamicSymbol.new line, str, array
    end

    def dstr line, str, array
      DynamicString.new line, str, array
    end
    
    def true line
      TrueLiteral.new line
    end

    def false line
      FalseLiteral.new line
    end

    def return line, value
      Return.new line, value
    end
    
    def lasgn line, name, value
      LocalVariableAssignment.new line, name, value
    end
    
    def hash line, array
      HashLiteral.new line, array
    end
    
    def cdecl line, expr, value
      ConstantAssignment.new line, expr, value
    end
    
    def op_cdecl line, var, value, op
      op_value = case op
      when :and
        And.new line, var, value
      when :or
        Or.new line, var, value
      else
        args = ArrayLiteral.new line, [value]
        SendWithArguments.new line, var, op, args
      end
      ConstantAssignment.new line, var, op_value
    end
  end
  
  # These builder methods process the null and void literals
  module BuilderMethods
    def null line
      NullLiteral.new line
    end
    
    def void line
      VoidLiteral.new line
    end
  end
  
  class NullLiteral < NilLiteral
    def to_sexp
      [:null]
    end
  end
  
  # Replace NilLiteral with NullLiteral and let original NilLiteral "disappear"
  NilLiteral = NullLiteral
  
  class ::CodeTools::Generator
    def push_void
      push_cpath_top
      find_const :Myco
      find_const :Void
    end
  end
  
  class VoidLiteral < Node
    def bytecode(g)
      pos(g)
      g.push_void
    end
    
    def to_sexp
      [:void]
    end
  end
  
end
