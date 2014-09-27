
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
  .to_ruby <<-'RUBY'
    (__c__ = ::Myco::Component.new([
      ::Myco.find_constant(:Foo),
      ::Myco.find_constant(:Bar),
      ::Myco.find_constant(:Baz)
    ], self, __FILE__, __LINE__)
    __c__.__last__ = __c__.module_eval {nil}
    __c__.instance)
  RUBY
  
  parse "Foo, ::Bar, Foo::Bar, ::Foo::Bar::Baz { }" do
    [:declobj, [:array,
     [:const, :Foo],
     [:colon3, :Bar],
     [:colon2, [:const, :Foo], :Bar],
     [:colon2, [:colon2, [:colon3, :Foo], :Bar], :Baz]
    ], [:null]]
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
  .to_ruby <<-'RUBY'
    Foo = (
      (__c__ = ::Myco::Component.new([
        ::Myco.find_constant(:Object)
      ], self, __FILE__, __LINE__)
      __c__.__last__ = __c__.module_eval {nil}
      __c__.instance)
    )
  RUBY
  
  parse "Foo < Object { }" do
    [:cdefn, :Foo, [:declobj, [:array, [:const, :Object]], [:null]]]
  end
  .to_ruby <<-'RUBY'
    (__d__ = Foo = (__c__ = ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], self, __FILE__, __LINE__)
    __c__.__last__ = __c__.module_eval {nil})
    __d__.__name__=:Foo
    __d__)
  RUBY
  
  parse "Foo << { }" do
    [:copen, :Foo, [:null]]
  end
  .to_ruby <<-'RUBY'
    ::Myco.find_constant(:Foo).module_eval {nil}
  RUBY
  
  parse <<-'code' do
    Foo << {
      Bar << { }
    }
  code
    [:copen, :Foo, [:block, [:copen, :Bar, [:null]]]]
  end
  .to_ruby <<-'RUBY'
    ::Myco.find_constant(:Foo).module_eval {(
      ::Myco.find_constant(:Bar).module_eval {nil}
    )}
  RUBY
  
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
  .to_ruby <<-'RUBY'
    (__c__ = ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], self, __FILE__, __LINE__)
    __c__.__last__ = __c__.module_eval {nil}
    __c__.instance).from_string(
      "  foo\n  bar\n"
    )
  RUBY
  
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
