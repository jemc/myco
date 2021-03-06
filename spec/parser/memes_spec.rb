
require 'spec_helper'


describe Myco::ToolSet::Parser, "Memes" do
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
      all:null
      none:void
      str  : "string"
      sym  :  :bol
      ssym : :"with spaces"
      s  :  self
      t:    true
      f:    false
      "x y" : z
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block, 
      [:meme, :foo,   [:array], [:args, :*], [:block, [:lambig, :one]]],
      [:meme, :bar,   [:array], [:args, :*], [:block, [:const, :Two]]],
      [:meme, :baz,   [:array], [:args, :*], [:block, [:lit, 3]]],
      [:meme, :deci,  [:array], [:args, :*], [:block, [:lit, 3.88]]],
      [:meme, :ary,   [:array], [:args, :*], [:block, [:array,
        [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4],
        [:lit, 5], [:lit, 6], [:lit, 7]]]],
      [:meme, :all,   [:array], [:args, :*], [:block, [:null]]],
      [:meme, :none,  [:array], [:args, :*], [:block, [:void]]],
      [:meme, :str,   [:array], [:args, :*], [:block, [:lit, "string"]]],
      [:meme, :sym,   [:array], [:args, :*], [:block, [:lit, :bol]]],
      [:meme, :ssym,  [:array], [:args, :*], [:block, [:lit, :"with spaces"]]],
      [:meme, :s,     [:array], [:args, :*], [:block, [:self]]],
      [:meme, :t,     [:array], [:args, :*], [:block, [:true]]],
      [:meme, :f,     [:array], [:args, :*], [:block, [:false]]],
      [:meme, :"x y", [:array], [:args, :*], [:block, [:lambig, :z]]],
    ]]
  end
  .to_ruby <<-'RUBY'
    ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
    .tap { |__c__| __c__.__last__ = __c__.component_eval {(
      declare_meme(:foo, [], nil, ::Myco.cscope.dup) { |*| (
        self.one
      )}
      declare_meme(:bar, [], nil, ::Myco.cscope.dup) { |*| (
        ::Myco.find_constant(:Two)
      )}
      declare_meme(:baz, [], nil, ::Myco.cscope.dup) { |*| (
        3
      )}
      declare_meme(:deci, [], nil, ::Myco.cscope.dup) { |*| (
        3.88
      )}
      declare_meme(:ary, [], nil, ::Myco.cscope.dup) { |*| (
        [
          1,
          2,
          3,
          4,
          5,
          6,
          7
        ]
      )}
      declare_meme(:all, [], nil, ::Myco.cscope.dup) { |*| (
        nil
      )}
      declare_meme(:none, [], nil, ::Myco.cscope.dup) { |*| (
        ::Myco::Void
      )}
      declare_meme(:str, [], nil, ::Myco.cscope.dup) { |*| (
        "string"
      )}
      declare_meme(:sym, [], nil, ::Myco.cscope.dup) { |*| (
        :bol
      )}
      declare_meme(:ssym, [], nil, ::Myco.cscope.dup) { |*| (
        :"with spaces"
      )}
      declare_meme(:s, [], nil, ::Myco.cscope.dup) { |*| (
        self
      )}
      declare_meme(:t, [], nil, ::Myco.cscope.dup) { |*| (
        true
      )}
      declare_meme(:f, [], nil, ::Myco.cscope.dup) { |*| (
        false
      )}
      declare_meme(:"x y", [], nil, ::Myco.cscope.dup) { |*| (
        self.z
      )}
    )}}.instance
  RUBY
  
  parse <<-'code' do
    Object {
      a: 1 + 2 * 3
      b: 1 / 2 - 3
      x: a . b % 3
      y: a ** b <=> x
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :a, [:array], [:args, :*], [:block,
        [:call, [:lit, 1], :+, [:arglist,
                [:call, [:lit, 2], :*, [:arglist, [:lit, 3]]]]]
      ]],
      [:meme, :b, [:array], [:args, :*], [:block,
        [:call, [:call, [:lit, 1], :/, [:arglist, [:lit, 2]]], 
                :-, [:arglist, [:lit, 3]]]
      ]],
      [:meme, :x, [:array], [:args, :*], [:block,
        [:call, [:call, [:lambig, :a], :b, [:arglist]],
                :%, [:arglist, [:lit, 3]]]
      ]],
      [:meme, :y, [:array], [:args, :*], [:block,
        [:call, [:call, [:lambig, :a], :**, [:arglist, [:lambig, :b]]], 
                :<=>, [:arglist, [:lambig, :x]]]
      ]]
    ]]
  end
  .to_ruby <<-'RUBY'
    ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
    .tap { |__c__| __c__.__last__ = __c__.component_eval {(
      declare_meme(:a, [], nil, ::Myco.cscope.dup) { |*| (
        1.__send__(
          :+,
          2.__send__(
            :*,
            3
          )
        )
      )}
      declare_meme(:b, [], nil, ::Myco.cscope.dup) { |*| (
        1.__send__(
          :/,
          2
        ).__send__(
          :-,
          3
        )
      )}
      declare_meme(:x, [], nil, ::Myco.cscope.dup) { |*| (
        self.a.b.__send__(
          :%,
          3
        )
      )}
      declare_meme(:y, [], nil, ::Myco.cscope.dup) { |*| (
        self.a.__send__(
          :**,
          self.b
        ).__send__(
          :<=>,
          self.x
        )
      )}
    )}}.instance
  RUBY
  
  parse <<-'code' do
    Object {
      a: -1-2--3.0
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :a, [:array], [:args, :*], [:block,
        [:call, [:call, [:lit, -1], :-, [:arglist, [:lit, 2]]],
                                    :-, [:arglist, [:lit, -3.0]]]
      ]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  {  one  }
      bar  :{  Two  }
      baz    :{3}  
      all:{null }
      else: { "what" }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args, :*], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args, :*], [:block, [:lit, 3]]],
      [:meme, :all, [:array], [:args, :*], [:block, [:null]]],
      [:meme, :else, [:array], [:args, :*], [:block, [:lit, "what"]]]
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
        null
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args, :*], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args, :*], [:block, [:lit, 3]]],
      [:meme, :all, [:array], [:args, :*], [:block, [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  |a|one
      bar  :  ||  Two  
      baz    :|c,d,*e|  3
      all:
      |a|
      null
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args, :c, :d, :"*e"], [:block, [:lit, 3]]],
      [:meme, :all, [:array], [:args, :a], [:block, [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  |a|{one}
      bar  :  ||{  Two  }
      baz    :|c,d,*e|  {  3
      }
      all:
      |a|
      {
        null
      }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args, :c, :d, :"*e"], [:block, [:lit, 3]]],
      [:meme, :all, [:array], [:args, :a], [:block, [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:|a|one, bar: || Two  ,,,  baz    :|c,d,*e|  3;4;5 , all: null; null ,
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args, :c, :d, :"*e"], [:block,
        [:lit, 3], [:lit, 4], [:lit, 5]]],
      [:meme, :all, [:array], [:args, :*], [:block, [:null], [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: { func() }
      bar: { func(1,2,null) }
      baz: {
        func(
          1,
          2,
          null
        )
      }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:call, [:self], :func, [:arglist]]]],
      [:meme, :bar, [:array], [:args, :*], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]]]],
      [:meme, :baz, [:array], [:args, :*], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: func()
      bar: func(1,2,null)
      baz:
      func(
        1,
        2,
        null
      )
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:call, [:self], :func, [:arglist]]]],
      [:meme, :bar, [:array], [:args, :*], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]]]],
      [:meme, :baz, [:array], [:args, :*], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: obj.func
      bar: obj.other.func(1,2,null).other(5,6)
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:call, [:lambig, :obj], :func, [:arglist]]]],
      [:meme, :bar, [:array], [:args, :*], [:block,
        [:call,
          [:call,
            [:call, [:lambig, :obj], :other, [:arglist]],
             :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]],
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
      [:meme, :foo, [:array], [:args, :*], [:block, [:lasgn, :x, [:lit, 8]]]],
      [:meme, :bar, [:array], [:args, :*], [:block,
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
      [:meme, :foo, [:array], [:args, :a, :b, :c, :d, :e, :f, :g], [:null]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: |a,b,
            c=0,,
            d = 5
            | { }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :a, :b, :c, :d, [:block,
        [:lasgn, :c, [:lit, 0]],
        [:lasgn, :d, [:lit, 5]]
      ]],
      [:null]]
    ]]
  end
  .to_ruby <<-'RUBY'
    ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
    .tap { |__c__| __c__.__last__ = __c__.component_eval {(
      declare_meme(:foo, [], nil, ::Myco.cscope.dup) { |a, b, c=0, d=5| nil}
    )}}.instance
  RUBY
  
  parse <<-'code' do
    Object {
      foo: |*a, &b| bar(*a, &b)
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :"*a", :"&b"], [:block,
        [:call, [:self], :bar, [:arglist,
          [:splat, [:lambig, :a]], [:block_pass, [:lambig, :b]]
        ]]
      ]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: |&blk| { bar |*yield_args| { blk.call(*yield_args) } }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :"&blk"], [:block,
        [:call, [:self], :bar, [:arglist,
          [:iter, [:args, :"*yield_args"], [:block,
            [:call, [:lambig, :blk], :call, [:arglist,
              [:splat, [:lambig, :yield_args]]
            ]]
          ]]
        ]]
      ]]
    ]]
  end
  .to_ruby <<-'RUBY'
    ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
    .tap { |__c__| __c__.__last__ = __c__.component_eval {(
      declare_meme(:foo, [], nil, ::Myco.cscope.dup) { |&blk| (
        self.bar { |*yield_args| (
          blk.call(*yield_args)
        )}
      )}
    )}}.instance
  RUBY
  
  parse <<-'code' do
    Object {
      foo: |a, b, *c, d: 1, e :2, f:, g :, **h, &i|
        foo(a, b, c, d: 1, e :2, f:3, g:4, &i)
        # TODO: foo(a, b, *c, d: 1, e :2, f:3, g:4, **h, &i)
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array],
        [:args, :a, :b, :"*c", :d, :e, :f, :g, :"**h", :"&i",
          [:kwargs, [:d, :e, :f, :g, :"**h"],
            [[:lasgn, :d, [:lit, 1]], [:lasgn, :e, [:lit, 2]]]]],
        [:block, [:call, [:self], :foo, [:arglist,
          [:lambig, :a], [:lambig, :b], [:lambig, :c], [:hash,
            [:lit, :d], [:lit, 1], [:lit, :e], [:lit, 2],
            [:lit, :f], [:lit, 3], [:lit, :g], [:lit, 4]],
          [:block_pass, [:lambig, :i]]]]]
      ]
    ]]
  end
  .to_ruby <<-'RUBY'
    ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
    .tap { |__c__| __c__.__last__ = __c__.component_eval {(
      declare_meme(:foo, [], nil, ::Myco.cscope.dup) { |a, b, *c, d:1, e:2, f:, g:, **h, &i| (
        self.foo(
          a,
          b,
          c,
          {
            :d => 1,
            :e => 2,
            :f => 3,
            :g => 4
          },
          &i
        )
      )}
    )}}.instance
  RUBY
  
  parse <<-'code' do
    Object {
      foo: Object { }
      bar: o = Object { }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:declobj, [:array, [:const, :Object]], [:null]]]],
      [:meme, :bar, [:array], [:args, :*], [:block,
        [:lasgn, :o, [:declobj, [:array, [:const, :Object]], [:null]]]]]
    ]]
  end
  .to_ruby <<-'RUBY'
    ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
    .tap { |__c__| __c__.__last__ = __c__.component_eval {(
      declare_meme(:foo, [], nil, ::Myco.cscope.dup) { |*| (
        ::Myco::Component.new([
          ::Myco.find_constant(:Object)
        ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
        .tap { |__c__| __c__.__last__ = __c__.component_eval {nil}}.instance
      )}
      declare_meme(:bar, [], nil, ::Myco.cscope.dup) { |*| (
        o = ::Myco::Component.new([
          ::Myco.find_constant(:Object)
        ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
        .tap { |__c__| __c__.__last__ = __c__.component_eval {nil}}.instance
      )}
    )}}.instance
  RUBY
  
  parse <<-'code' do
    Object {
      foo: a = 88
      bar: a(99, 101) = 88
      baz: a.b(99, 101) = 88
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:lasgn, :a, [:lit, 88]]]],
      [:meme, :bar, [:array], [:args, :*], [:block,
        [:call, [:self], :a=, [:arglist,
          [:lit, 88], [:lit, 99], [:lit, 101]]]]],
      [:meme, :baz, [:array], [:args, :*], [:block,
        [:call, [:lambig, :a], :b=, [:arglist,
          [:lit, 88], [:lit, 99], [:lit, 101]]]]],
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: a = z[1,2,3]
      bar: a[88, 99] = 101
      baz: a.b[88, 99] = 101
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:lasgn, :a, [:call, [:lambig, :z], :[], [:arglist,
          [:lit, 1], [:lit, 2], [:lit, 3]]]]]],
      [:meme, :bar, [:array], [:args, :*], [:block,
        [:call, [:lambig, :a], :[]=, [:arglist,
          [:lit, 88], [:lit, 99], [:lit, 101]]]]],
      [:meme, :baz, [:array], [:args, :*], [:block,
        [:call, [:call, [:lambig, :a], :b, [:arglist]], :[]=, [:arglist,
          [:lit, 88], [:lit, 99], [:lit, 101]]]]],
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: a = !b * !!c
      bar: a.+ * b.-() / c.%(1, 2, 3)
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:lasgn, :a, [:call,
          [:call, [:lambig, :b], :!, [:arglist]], :*, [:arglist,
            [:call, [:call, [:lambig, :c], :!, [:arglist]], :!, [:arglist]]]]]
      ]],
      [:meme, :bar, [:array], [:args, :*], [:block,
        [:call,
          [:call, [:call, [:lambig, :a], :+, [:arglist]], :*, [:arglist,
            [:call, [:lambig, :b], :-, [:arglist]]]], :/,
          [:arglist, [:call, [:lambig, :c], :%, [:arglist,
            [:lit, 1], [:lit, 2], [:lit, 3]]]]]
      ]]
    ]]
  end
  
end
