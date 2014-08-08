
require 'spec_helper'


describe Myco::ToolSet::Parser, "Declarations" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      Object { }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block, 
             [:declobj, [:array, [:const, :Object]], [:null]]]]
  end
  
  parse "Object { }" do
    [:declobj, [:array, [:const, :Object]], [:null]]
  end
  
  parse "Object{}" do
    [:declobj, [:array, [:const, :Object]], [:null]]
  end
  
  parse <<-'code' do
    Object {
      
    }
  code
    [:declobj, [:array, [:const, :Object]], [:null]]
  end
  
  parse <<-'code' do
    Object
    {
      
    }
  code
    [:declobj, [:array, [:const, :Object]], [:null]]
  end
  
  parse "Foo,Bar,Baz { }" do
    [:declobj, [:array, [:const, :Foo], [:const, :Bar], [:const, :Baz]], [:null]]
  end
  
  parse <<-'code' do
    Foo  ,  Bar,
    Baz
    {
      
    }
  code
    [:declobj, [:array, [:const, :Foo], [:const, :Bar], [:const, :Baz]], [:null]]
  end
  
  parse "Foo: Object { }" do
    [:cdecl, :Foo, [:block, [:declobj, [:array, [:const, :Object]], [:null]]]]
  end
  
  parse "Foo < Object { }" do
    [:cdefn, :Foo, [:declobj, [:array, [:const, :Object]], [:null]]]
  end
  
  parse <<-'code' do
    Object @@@
      foo
      bar
    @@@
  code
    [:declstr, [:array, [:const, :Object]], [:str, <<-DECLSTR]]
      foo
      bar
    DECLSTR
  end
  
  parse <<-'code' do
    Foo: Object @@@
      bar
    @@@
  code
    [:cdecl, :Foo, [:block,
      [:declstr, [:array, [:const, :Object]], [:str, "      bar\n"]]
    ]]
  end
  
  parse <<-'code' do
    Object @@@
      @foo
      bar @@@
      @@baz
    @@@
  code
    [:declstr, [:array, [:const, :Object]],
      [:str, "      @foo\n      bar @@@\n      @@baz\n"]]
  end
  
  parse <<-'code' do
    Object foo
      bar
    foo
  code
    [:declstr, [:array, [:const, :Object]],
      [:str, "      bar\n"]]
  end
  
  parse <<-'code' do
    Object 123_TEST
      foo
    TEST_321
  code
    [:declstr, [:array, [:const, :Object]],
      [:str, "      foo\n"]]
  end
  
  parse <<-'code' do
    Object >)+-foo><BAR+-]]]}}}
      foo
    {{{[[[-+BAR><foo-+(<
  code
    [:declstr, [:array, [:const, :Object]],
      [:str, "      foo\n"]]
  end
  
end
