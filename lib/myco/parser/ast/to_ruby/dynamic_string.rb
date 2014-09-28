
class CodeTools::AST::DynamicString
  def to_ruby g
    inspect_escape = Proc.new { |str| str.inspect[1...-1] }
    
    g.add('"')
      g.add(inspect_escape.call(@string))
      @array.each_slice(2) { |interpolated, inner_string|
        g.add('#{'); g.add(interpolated.value); g.add('}')
        g.add(inspect_escape.call(inner_string.value))
      }
    g.add('"')
  end
end
