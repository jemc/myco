
require 'spec_helper'


describe Myco::ToolSet::Parser, "Quests" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      a: foo.?bar
      b: foo .
             ? bar
      c: foo(1).?bar(2,3)
      d: foo(1) { 55 } .? bar(2,3) { 66 }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :a, [:array], [:args, :*], [:block,
        [:quest, [:lambig, :foo], [:call, [:qrcvr], :bar, [:arglist]]]
      ]],
      [:meme, :b, [:array], [:args, :*], [:block,
        [:quest, [:lambig, :foo], [:call, [:qrcvr], :bar, [:arglist]]]
      ]],
      [:meme, :c, [:array], [:args, :*], [:block,
        [:quest, [:call, [:self], :foo, [:arglist, [:lit, 1]]],
                 [:call, [:qrcvr], :bar, [:arglist, [:lit, 2], [:lit, 3]]]]
      ]],
      [:meme, :d, [:array], [:args, :*], [:block,
        [:quest, [:call, [:self], :foo, [:arglist, [:lit, 1],
                   [:iter, [:args], [:block, [:lit, 55]]]]],
                 [:call, [:qrcvr], :bar, [:arglist, [:lit, 2], [:lit, 3],
                   [:iter, [:args], [:block, [:lit, 66]]]]]]
      ]],
    ]]
  end
  
end
