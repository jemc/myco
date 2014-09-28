
require 'spec_helper'


describe Myco::ToolSet::Parser, "Categories" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    [foo]
  code
    [:category, :"foo", [:null]]
  end
  .to_ruby <<-'RUBY'
    __category__(:foo).module_eval {nil}
  RUBY
  
  parse <<-'code' do
    [foo\[bar\]baz]
  code
    [:category, :"foo[bar]baz", [:null]]
  end
  
  parse <<-'code' do
    Object {
      Foo
      [one]
      Bar
      Bar
      Bar
      [two]
      Baz
      Baz
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:const, :Foo],
      [:category, :one, [:block,
        [:const, :Bar], [:const, :Bar], [:const, :Bar]]],
      [:category, :two, [:block,
        [:const, :Baz], [:const, :Baz]]]
    ]]
  end
  .to_ruby <<-'RUBY'
    (__c__ = ::Myco::Component.new([
      ::Myco.find_constant(:Object, __cscope__)
    ], self, __FILE__, __LINE__)
    __c__.__last__ = __c__.module_eval {(
      __cscope__ = Rubinius::ConstantScope.new(self, __cscope__)
      __cscope__.set_myco_component
      ::Myco.find_constant(:Foo, __cscope__)
      __category__(:one).module_eval {(
        __cscope__ = Rubinius::ConstantScope.new(self, __cscope__)
        __cscope__.set_myco_category
        ::Myco.find_constant(:Bar, __cscope__)
        ::Myco.find_constant(:Bar, __cscope__)
        ::Myco.find_constant(:Bar, __cscope__)
        __cscope__ = __cscope__.parent
      )}
      __category__(:two).module_eval {(
        __cscope__ = Rubinius::ConstantScope.new(self, __cscope__)
        __cscope__.set_myco_category
        ::Myco.find_constant(:Baz, __cscope__)
        ::Myco.find_constant(:Baz, __cscope__)
        __cscope__ = __cscope__.parent
      )}
      __cscope__ = __cscope__.parent
    )}
    __c__.instance)
  RUBY
  
  parse <<-'code' do
    Object {
      Foo
      [one]
      [two]
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:const, :Foo],
      [:category, :one, [:null]],
      [:category, :two, [:null]]
    ]]
  end
  
end
