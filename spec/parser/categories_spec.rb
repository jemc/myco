
require 'spec_helper'


describe Myco::ToolSet::Parser, "Categories" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    [foo]
  code
    [:category, :"foo", [:null]]
  end
  
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
