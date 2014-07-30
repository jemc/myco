
require 'spec_helper'


describe Myco::ToolSet::Parser, "Decorations" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      on foo: nil
      one two three: nil
      sym "str.ng": nil
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo,   [:array, [:lit, :on]],
        [:args], [:block, [:nil]]],
      [:meme, :three, [:array, [:lit, :two], [:lit, :one]],
        [:args], [:block, [:nil]]],
      [:meme, :"str.ng", [:array, [:lit, :sym]],
        [:args], [:block, [:nil]]]
    ]]
  end
  
end
