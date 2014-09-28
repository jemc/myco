
module Myco
  
  # Boolean && by result of false? predicate with lazy evaluation of right hand
  def self.and left#, &right
    return left if left.false?
    return yield
  end
  
  # Boolean || by result of false? predicate with lazy evaluation of right hand
  def self.or left#, &right
    return left unless left.false?
    return yield
  end
  
end
