
module Myco
  module DEV
    class COUNTER
      class << self
        def coll
          @coll ||= begin
            at_exit { print! }
            Hash.new(0)
          end
        end
        
        def count(*items)
          coll[items] += 1
        end
        
        def print!
          STDOUT.puts "#{self} report:"
          coll.to_a.sort_by { |x| x.last }.each do |key,val|
            STDOUT.puts "  #{val} : #{key.inspect}"
          end
        end
      end
    end
  end
end
