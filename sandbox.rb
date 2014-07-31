
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/eval'
require_relative 'lib/myco/bootstrap'


module Myco
  def self.myco_open path
    begin
      Myco.eval File.read(path), nil, path
    rescue Exception=>e
      puts e.message
      puts e.awesome_backtrace.show
    end
  end
  
  myco_open './lib/myco/bootstrap.my'
  myco_open './sandbox.my'
end
