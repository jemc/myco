
require 'spec_helper'


module Myco
  def self.myco_open path
    begin
      Myco.eval File.read(path), nil, path
    rescue Exception=>e
      puts e.message
      puts e.awesome_backtrace.show
    end
  end
end

Myco.myco_open 'lib/myco/bootstrap.my'
Myco.myco_open 'spec/myco/BasicSpec.my'
[
  'spec/myco/basic_spec.my',
].each do |path|
  group = Myco.myco_open path
  
  describe group.name do
    group.tests.memes.each do |name, test|
      it name do
        group.instance_variable_set(:@harness, self)
        
        test.result
      end
    end
  end
end
