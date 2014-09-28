
class CodeTools::AST::BlockPass
  def to_ruby g
    g.add("&"); g.add(@body)
  end
end
