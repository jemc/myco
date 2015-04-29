
module Myco
  class << self
    dynamic_method(:undefined) { |g|
      g.push_undef
      g.ret
    }
  end
end
