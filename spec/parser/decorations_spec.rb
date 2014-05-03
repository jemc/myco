
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
      [:bind, :foo,   [:array, [:lit, :on]],
        [:args], [:block, [:nil]]],
      [:bind, :three, [:array, [:lit, :two], [:lit, :one]],
        [:args], [:block, [:nil]]],
      [:bind, :"str.ng", [:array, [:lit, :sym]],
        [:args], [:block, [:nil]]]
    ]]
  end
  
end
