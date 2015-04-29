
class ::Array
  # Create a method named :__tuple__ that uses the access_Array_tuple primitive.
  attr_reader_specific :tuple, :__tuple__
end

module Myco
  class << self
    def tuple(*ary)
      ary.__tuple__
    end
  end
end
