
module Myco
  
  # Logical branching operator with lazy evaluation of right hand
  def self.branch_op type, left
    case type
    when :"&&"; return left if left.false?
    when :"||"; return left unless left.false?
    when :"??"; return left unless left.void?
    when :"&?"; return ::Myco::Void if left.false?
    when :"|?"; return ::Myco::Void unless left.false?
    end
    return yield # evaluate and return right hand
  end
  
end
