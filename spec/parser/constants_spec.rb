
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
  
  parse "::Foo::Bar" do
    [:colon2, [:colon3, :Foo], :Bar]
  end
  
end
