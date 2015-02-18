
module CodeTools::AST
  
  # These builder methods are copied directly from rubinius-processor
  # TODO: remove and Myco-ize all dependencies on rubinius-processor and rubinius-ast
  module BuilderMethods
    def colon2 loc, outer, name
      if outer
        if outer.kind_of? ConstantAccess and
           outer.name == :Rubinius
          case name
          when :Type
            TypeConstant.new loc.line
          when :Mirror
            MirrorConstant.new loc.line
          else
            ScopedConstant.new loc.line, outer, name
          end
        else
          ScopedConstant.new loc.line, outer, name
        end
      else
        ConstantAccess.new loc.line, name
      end
    end
    
    def colon3 loc, name
      ToplevelConstant.new loc.line, name
    end
    
    def const loc, name
      ConstantAccess.new loc.line, name
    end
    
    def lit loc, sym
      SymbolLiteral.new loc.line, sym
    end
    
    def args loc, required, optional, splat, post, kwargs, kwrest, block
      Parameters.new loc.line, required, optional, splat, post, kwargs, kwrest, block
    end
    
    def self loc
      Self.new loc.line
    end
    
    def block loc, array
      Block.new loc.line, array
    end
    
    def str loc, str
      StringLiteral.new loc.line, str
    end
    
    def splat loc, expr
      SplatValue.new loc.line, expr
    end
    
    def block_pass loc, arguments, body
      BlockPass19.new loc.line, arguments, body
    end
    
    def evstr loc, value
      if value
        ToString.new loc.line, value
      else
        StringLiteral.new loc.line, ""
      end
    end
    
    def dsym loc, str, array
      DynamicSymbol.new loc.line, str, array
    end

    def dstr loc, str, array
      DynamicString.new loc.line, str, array
    end
    
    def true loc
      TrueLiteral.new loc.line
    end

    def false loc
      FalseLiteral.new loc.line
    end

    def return loc, value
      Return.new loc.line, value
    end
    
    def lasgn loc, name, value
      LocalVariableAssignment.new loc.line, name, value
    end
    
    def hash loc, array
      HashLiteral.new loc.line, array
    end
    
    def cdecl loc, expr, value
      ConstantAssignment.new loc.line, expr, value
    end
    
    def op_cdecl loc, var, value, op
      op_value = case op
      when :and
        And.new loc.line, var, value
      when :or
        Or.new loc.line, var, value
      else
        args = ArrayLiteral.new loc.line, [value]
        SendWithArguments.new loc.line, var, op, args
      end
      ConstantAssignment.new loc.line, var, op_value
    end
  end
  
  # These builder methods process the null and void literals
  module BuilderMethods
    def null loc
      NullLiteral.new loc.line
    end
    
    def void loc
      VoidLiteral.new loc.line
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
