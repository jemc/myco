
require 'spec_helper'

Myco.eval_file 'lib/myco/bootstrap.my'
Myco.eval_file 'spec/myco/BasicSpec.my'


[
  'spec/myco/BasicSpec.test.my',
].each do |path|
  group = Myco.eval_file path
  
  describe group.name do
    group.tests.memes.each do |name, test|
      it name do
        group.instance_variable_set(:@harness, self)
        
        test.result
      end
    end
  end
end
