
require 'spec_helper'


describe Myco::ToolSet::Parser, "Constants" do
  extend SpecHelpers::ParserHelper
  
  parse "Object"   do [:const, :Object]  end
  parse "OBJECT"   do [:const, :OBJECT]  end
  parse "Obj_3cT"  do [:const, :Obj_3cT] end
  parse "O"        do [:const, :O]       end
  
  parse "Foo::Bar::Baz" do
    [:colon2, [:colon2, [:const, :Foo], :Bar], :Baz]
  end
  .to_ruby <<-'RUBY'
    ::Myco.find_constant(:Foo)::Bar::Baz
  RUBY
  
  parse "::Foo::Bar" do
    [:colon2, [:colon3, :Foo], :Bar]
  end
  .to_ruby <<-'RUBY'
    ::Foo::Bar
  RUBY
  
end
