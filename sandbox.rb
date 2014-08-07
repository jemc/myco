
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/eval'
require_relative 'lib/myco/bootstrap'
require_relative 'lib/myco/backtrace'


module Myco
  def self.myco_open path
    begin
      Myco.eval File.read(path), nil, path
    rescue Exception=>e
      puts e.awesome_backtrace.show
      puts e.awesome_backtrace.first_color + e.message + "\033[0m"
      puts
      exit(1)
    end
  end
  
  myco_open './lib/myco/bootstrap.my'
  myco_open './sandbox.my'
end
