
module CodeTools::AST
  class Parameters
    def to_ruby g
      list = []
      list_add = Proc.new { |&blk| list.push(Proc.new(&blk)) }
      
      @required.each { |item| list_add.call { g.add(item.to_s) } }
      
      if @defaults
        @defaults.arguments.each { |asgn|
          name = asgn.name
          value = asgn.value
          list_add.call {
            g.add("#{name}=")
            g.add(value) unless value.is_a?(SymbolLiteral) and value.value==:*
          }
        }
      end
      
      if @splat == :*
        list_add.call { g.add("*") }
      elsif @splat
        list_add.call { g.add("*#{@splat}") }
      end
      
      if @keywords
        @keywords.arguments.each { |asgn|
          name = asgn.name
          value = asgn.value
          list_add.call {
            g.add("#{name}:")
            g.add(value) unless value.is_a?(SymbolLiteral) and value.value==:*
          }
        }
        
        if @keywords.kwrest == true
          list_add.call { g.add("**") }
        elsif @keywords.kwrest
          list_add.call { g.add("**#{@keywords.kwrest.name}") }
        end
      end
      
      if @block_arg
        list_add.call { g.add("&#{@block_arg.name}") }
      end
      
      if list.empty?
        g.add("||")
      else
        g.add("|")
        g.push_indent
          list[0...-1].each { |proc| proc.call; g.add(", ") }
          list.last.tap     { |proc| proc.call }
        g.pop_indent
        g.add("|")
      end
    end
  end
end
