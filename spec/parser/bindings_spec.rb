
require 'spec_helper'


describe Myco::ToolSet::Parser, "Bindings" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      foo:    one
      bar  :  Two  
      baz    :3
      deci  : 3.88
      ary :  [1,2, 3,
              4
              5,,
              6
              
              7,
             ]
      all:nil
      str  : "string"
      sym  :  :bol
      ssym : :"with spaces"
      t:    true
      f:    false
      "x y" : z
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block, 
      [:bind, :foo,   [:array], [:args], [:block, [:lambig, :one]]],
      [:bind, :bar,   [:array], [:args], [:block, [:const, :Two]]],
      [:bind, :baz,   [:array], [:args], [:block, [:lit, 3]]],
      [:bind, :deci,  [:array], [:args], [:block, [:lit, 3.88]]],
      [:bind, :ary,   [:array], [:args], [:block, [:array,
        [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4],
        [:lit, 5], [:lit, 6], [:lit, 7]]]],
      [:bind, :all,   [:array], [:args], [:block, [:nil]]],
      [:bind, :str,   [:array], [:args], [:block, [:lit, "string"]]],
      [:bind, :sym,   [:array], [:args], [:block, [:lit, :bol]]],
      [:bind, :ssym,  [:array], [:args], [:block, [:lit, :"with spaces"]]],
      [:bind, :t,     [:array], [:args], [:block, [:true]]],
      [:bind, :f,     [:array], [:args], [:block, [:false]]],
      [:bind, :"x y", [:array], [:args], [:block, [:lambig, :z]]],
    ]]
  end
  
  parse <<-'code' do
    Object {
      a: 1 + 2 * 3
      b: 1 / 2 - 3
      x: a . b % 3
      y: a ** b <=> x
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :a, [:array], [:args], [:block,
        [:call, [:lit, 1], :+, [:arglist,
                [:call, [:lit, 2], :*, [:arglist, [:lit, 3]]]]]
      ]],
      [:bind, :b, [:array], [:args], [:block,
        [:call, [:call, [:lit, 1], :/, [:arglist, [:lit, 2]]], 
                :-, [:arglist, [:lit, 3]]]
      ]],
      [:bind, :x, [:array], [:args], [:block,
        [:call, [:call, [:lambig, :a], :b, [:arglist]],
                :%, [:arglist, [:lit, 3]]]
      ]],
      [:bind, :y, [:array], [:args], [:block,
        [:call, [:call, [:lambig, :a], :**, [:arglist, [:lambig, :b]]], 
                :<=>, [:arglist, [:lambig, :x]]]
      ]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  {  one  }
      bar  :{  Two  }
      baz    :{3}  
      all:{nil }
      else: { "what" }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args], [:block, [:lambig, :one]]],
      [:bind, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:bind, :baz, [:array], [:args], [:block, [:lit, 3]]],
      [:bind, :all, [:array], [:args], [:block, [:nil]]],
      [:bind, :else, [:array], [:args], [:block, [:lit, "what"]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: {
        one
      }
      bar:{ Two
        }
      baz  :{
        3}
      all: \
        nil
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args], [:block, [:lambig, :one]]],
      [:bind, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:bind, :baz, [:array], [:args], [:block, [:lit, 3]]],
      [:bind, :all, [:array], [:args], [:block, [:nil]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  |a|one
      bar  :  ||  Two  
      baz    :|c,d,e|  3
      all:
      |a|
      nil
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
      [:bind, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:bind, :baz, [:array], [:args, :c, :d, :e], [:block, [:lit, 3]]],
      [:bind, :all, [:array], [:args, :a], [:block, [:nil]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  |a|{one}
      bar  :  ||{  Two  }
      baz    :|c,d,e|  {  3
      }
      all:
      |a|
      {
        nil
      }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
      [:bind, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:bind, :baz, [:array], [:args, :c, :d, :e], [:block, [:lit, 3]]],
      [:bind, :all, [:array], [:args, :a], [:block, [:nil]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: { func() }
      bar: { func(1,2,nil) }
      baz: {
        func(
          1,
          2,
          nil
        )
      }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist]]]],
      [:bind, :bar, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]]]],
      [:bind, :baz, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: func()
      bar: func(1,2,nil)
      baz:
      func(
        1,
        2,
        nil
      )
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist]]]],
      [:bind, :bar, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]]]],
      [:bind, :baz, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: obj.func
      bar: obj.other.func(1,2,nil).other(5,6)
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args], [:block,
        [:call, [:lambig, :obj], :func, [:arglist]]]],
      [:bind, :bar, [:array], [:args], [:block,
        [:call,
          [:call,
            [:call, [:lambig, :obj], :other, [:arglist]],
             :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]],
           :other, [:arglist, [:lit, 5], [:lit, 6]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: x = 8
      bar: a.b = foo
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args], [:block, [:lasgn, :x, [:lit, 8]]]],
      [:bind, :bar, [:array], [:args], [:block,
        [:call, [:lambig, :a], :b=, [:arglist, [:lambig, :foo]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: |a,b, c,
        d
        e,,
        f
        
        g,
      | { }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :foo, [:array], [:args, :a, :b, :c, :d, :e, :f, :g], [:nil]]
    ]]
  end
  
end
