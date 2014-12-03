# Ruby basics

Ruby is "a dynamic, open source programming language with a focus on
simplicity and productivity." (quoted from
[ruby-lang.org](https://www.ruby-lang.org/)). Fortunately, you do *not* have
to be a ruby expert to:

* experiment with Alf on [www.try-alf.org](http://www.try-alf.org),
* use the command line tool,
* write simple Alf-based scripts that connect to files and databases

Integrating the query language inside ruby-based software is another story, of
course. This page provides you with sufficient knowledge of ruby for the
scenarios above. Don't miss the [Alf in Ruby](/doc/pages/alf-in-ruby) and [Alf in
Shell](/doc/pages/alf-in-shell) pages for getting started concretely.

An important note first. Relational algebra can be seen as a purely functional
kind of programming. For this reason and on very intent, the overview here
does not cover variables, affectation (e.g. `x = 2`) or operators that involve
mutation of shared state (e.g. classes and object-oriented programming). All
are valid in Ruby but not strictly necessary in the context of Alf.

## Types and values

Data management is first and foremost about _types_ and _values_. Alf uses the
type system of ruby as a foundation. Useful value literals that you might
encounter when learning Alf are:

```
'a string'   # type: String
"a string"   # type: String, similar but supports interpolation
12           # type: Integer
12.0         # type: Float
true         # type: TrueClass, ... ruby has no Boolean, Alf fakes one sometimes
false        # type: FalseClass
/[a-b]+/     # type: Regexp
:hello       # type: Symbol (used by Alf for attribute names, aka AttrName)
[1, 2, 3]    # type: Array (ruby supports heteroegenous arrays, we dont't use them here)
{a: 1, b: 2} # type: Hash (aka dictionnary, or map, Alf uses them a lot. see later)
->(t){ ... } # type: Proc (aka block or function, see later too)
```

## Operators

Operators are seen here a pure functions that compute values from other
values. Alf comes with a (somewhat strange) mix of infix, prefix and suffix
syntaxes for operator invocations, all inherited from ruby. Unfortunately,
you can't currently mix the styles, and have to follow the rules described
now.

The infix notation is commonly used for comparisons, common arithmetic,
boolean algebra, set-based operations on arrays, matching against regular
expression, etc. A few examples you might encounter in Alf's documentation:

```
2 == 3              # false
2 < 3               # true
1 + 1               # 2
12 * 10             # 120
2 ** 8              # 258
true | false        # true
true & false        # false
[17, 13] | [13, 4]  # [17, 13, 4], i.e. set-union 
[17, 13] & [13, 4]  # [13], i.e. set-intersection 
"acbbcad" =~ /b+/   # 2, one-or-more 'b's found at index 2
```

The suffix notation is commonly used for invoking operators in an object-oriented
kind of style (we also say 'sending a message'), and for selecting attributes
on tuples (which is a special case of the former):

```
"hello".upcase        # "UPCASE"
[1, 2, 3].empty?      # false
[1, 2, 3].join(';')   # "1;2;3"
t.name                # "Jones" if t is Tuple(name: "Jones"), see later
```

The prefix notation is idiomatic in Alf when writing queries. This kind of
syntax has been chosen for its functional nature, that nicely fits with the
closure property of relational algebra (the fact that you invoke an operator
on the result of a previous one):

```
project(join(shipments, parts), [:pid, :name, :qty])
```

We also occasionally use the prefix notation for invoking type selectors,
also called "explicit coercion functions" in Alf:

```
Date("2013-10-17")     # coerces a String to a Date value
Relation([             # coerces a Array of Hashes to a Relation
  {name: 'Smith'},
  {name: 'Jones'}
])
```

We also occasionaly define new operators. Ruby is dynamically typed and
therefore does not require or even provide you with a way to make argument
types explicit. For instance, for a scalar operator:

```
def double(x)
  2*x
end
```

Another example, for defining a new relational operator as a shortcut for a
longer expression (something we frequently use in this documentation and is
also idiomatic for building domain-specific relational abstractions):

```
def in_london(operand)
  restrict(operand, city: 'London')
end
```

## Hashes

Hashes are very common in Ruby, so common that dedicated syntaxes exist
for them. A hash captures `(key, value)` pairs, where both the key and the
value can be arbitrary values:

```
{ "city" => "London", "price" => 17.0, "suppliers" => ["Jones", "Smith"] }
```

Now, it is very common to use Symbols (e.g. `:city`) instead of Strings for
keys: 

```
{ :city => "London", :price => 17.0, :suppliers => ["Jones", "Smith"] }
```

A special syntax can be used in this case that is more compact. The following
Hash denotes the same value as the one above:

```
{ city: "London", price: 17.0, suppliers: ["Jones", "Smith"] }
```

Hashes can of course be passed as arguments when invoking operators. A good
example is when invoking Alf's `restrict` operator:

```
restrict(suppliers, {city: 'London', status: 20})
```

When a Hash is passed as last argument of an operator, the brackets can be
safely ommited in ruby, leading to a nicer syntax:

```
restrict(suppliers, city: 'London', status: 20)
```

## Procs

Procs can be seen as anonymous operators that can be passed as arguments and
used as any other kind of value. For instance, one may define the `double`
operator shown previously, using the anonymous syntax this time:

```
->(x){ x*2 }
```

A typical usage of Procs in Alf is the `restrict` and `extend` operators.
Observe how, in the second case, the Proc is actually mapped to a key in a
Hash:

```
restrict(suppliers, ->(t){ t.status > 20 })
extend(suppliers, big_name: ->(t){ t.name.upcase })
```
