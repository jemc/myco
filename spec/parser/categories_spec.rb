
require 'spec_helper'


describe Myco::ToolSet::Parser, "Categories" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    [foo]
  code
    [:category, :"foo", [:null]]
  end
  .to_ruby <<-'RUBY'
    __category__(:foo).component_eval {nil}
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
    ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
    .tap { |__c__| __c__.__last__ = __c__.component_eval {(
      ::Myco.find_constant(:Foo)
      __category__(:one).component_eval {(
        ::Myco.find_constant(:Bar)
        ::Myco.find_constant(:Bar)
        ::Myco.find_constant(:Bar)
      )}
      __category__(:two).component_eval {(
        ::Myco.find_constant(:Baz)
        ::Myco.find_constant(:Baz)
      )}
    )}}.instance
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
