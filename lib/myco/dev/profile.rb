
module Myco
  module DEV
    def self.profile(show=true, &block)
      require 'rubinius/profiler'
      prof = Rubinius::Profiler::Instrumenter.new
      prof.profile &block
      prof.show if show
      prof
    end
  end
end
