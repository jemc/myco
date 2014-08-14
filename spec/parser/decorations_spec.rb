
require 'spec_helper'


describe Myco::ToolSet::Parser, "Decorations" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      on foo: null
      one two three: null
      sym "str.ng": null
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo,   [:array, [:lit, :on]],
        [:args], [:block, [:null]]],
      [:meme, :three, [:array, [:lit, :two], [:lit, :one]],
        [:args], [:block, [:null]]],
      [:meme, :"str.ng", [:array, [:lit, :sym]],
        [:args], [:block, [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      on foo
      one two three
      sym "str.ng"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo,   [:array, [:lit, :on]],
        [:args], [:null]],
      [:meme, :three, [:array, [:lit, :two], [:lit, :one]],
        [:args], [:null]],
      [:meme, :"str.ng", [:array, [:lit, :sym]],
        [:args], [:null]]
    ]]
  end
  
end
