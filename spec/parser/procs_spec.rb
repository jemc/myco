
require 'spec_helper'


describe Myco::ToolSet::Parser, "Procs" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      foo: |x=2,&blk| blk.call + x
      bar: 5 + foo { 3 }
      baz: foo(1) { 5 }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array],
        [:args, :x, :"&blk", [:block, [:lasgn, :x, [:lit, 2]]]], [:block,
          [:call, [:call, [:lambig, :blk], :call, [:arglist]],
            :+, [:arglist, [:lambig, :x]]]
          ]
        ],
      [:meme, :bar, [:array],
        [:args], [:block,
          [:call, [:lit, 5], :+, [:arglist, [:call, [:self],
            :foo, [:arglist, [:iter, [:args], [:lit, 3]]]]]]
          ]
        ],
      [:meme, :baz, [:array],
        [:args], [:block,
          [:call, [:self],
            :foo, [:arglist, [:lit, 1], [:iter, [:args], [:lit, 5]]]]
        ]
      ]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: baz         |a,b,c| { a }
      baz: baz (1,2,3) |a,b,c| { b }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block,
        [:call, [:self], :baz, [:arglist,
          [:iter, [:args, :a, :b, :c], [:lambig, :a]]
        ]]
      ]],
      [:meme, :baz, [:array], [:args], [:block,
        [:call, [:self], :baz, [:arglist,
          [:lit, 1], [:lit, 2], [:lit, 3],
          [:iter, [:args, :a, :b, :c], [:lambig, :b]]
        ]]
      ]]
    ]]
  end
  
end
