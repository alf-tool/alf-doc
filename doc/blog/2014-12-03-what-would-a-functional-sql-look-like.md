<div class="blog-post-date">2014, December 3</div>

# What would a functional SQL look like?

In short, probably something like this:

```ruby
suppliers
  | join shipments                     # From suppliers and their shipments
  | where @city = "London"             #   among those located in London
  | select @sid, @pid, @name, @qty     #   select the ids, supplier name and shipped qty 
```

Before explaining this syntax, why it matters (does it?), and the advantages it has, let me explain the motivation of this work. (If you are intrigued by the functional stuff in the title and want the explanation right away, you can simply skip the next section.)

(This is the first of a - I hope long - series of posts on the design of a data manipulation language. Keep in touch by following me on twitter or asking by email to be notified when next essays appear.)

## Motivation

I started working on the syntax above after having played with [Eve](http://incidentalcomplexity.com/), by Chris Granger & al. Eve embeds a datalog/relational-like manipulation language. When playing with Eve examples a few weeks ago, I was slightly hindered of using Eve syntax without completely understanding its intended semantics. I've therefore tried to make a precise sense of it by myself. Doing so, I ended up with a slightly different proposal, a mix between Eve and [Elixir's pipe operator](http://elixir-lang.org/docs/stable/elixir/Kernel.html#|>/2), à la sauce [Alf](http://www.try-alf.org/blog/2013-10-21-relations-as-first-class-citizen). I'm not sure it is even similar to Eve, but is that important? The credits are, because the good parts of the syntax above are thus borrowed from Eve and Elixir. The semantics here is mine (see below), yet the relational algebra itself is from C.J. Date and Hugh Darwen [**Tutorial D**](http://www.thethirdmanifesto.com/).

More generally, it's been more than one year since the [introductory post on Alf and relations as first-class citizen](http://www.try-alf.org/blog/2013-10-21-relations-as-first-class-citizen). In the past year, I've collected an impressive amount of experience using Alf on different database and software engineering projects, with many successes and only few difficulties. To quickly summarize the approach.

### Functional

Alf emphasizes the functional nature of relational algebra (RA). It shows that querying a database amounts at constructing a result from smaller results, following the software requirements at hand:

```try
qry = join(suppliers, shipments)               # From suppliers and their shipments
qry = restrict(qry, city: "London")            #   among those located in London
qry = project(qry, [:sid, :pid, :name, :qty])  #   select the ids, supplier name and shipped qty
```

Without relying on variable assignment (which is not that functional-minded after all), you end up with something like this (referred to as Alf's purely functional syntax hereafter):

```try
project(
  restrict(
    join(suppliers,shipments),
    city: "London"),
  [:sid, :pid, :name, :qty])
```

### Powerful

By exposing relational algebra as strict application of functions to argument *values* (in contrast to dedicated syntactic terms), Alf provides a dynamic way of writing queries. Possibly, it should be thought of as a data manipulation language more than a query language.

To give a trivial example of what I'm talking about, consider the query below. The attribute
list on which the projection applies can easily be computed. That is, the projection operator takes an attribute list *value* as argument, and that value can result from evaluating an
expression (that's a sharp tool, I know, I'll come back to that):

```try
project(suppliers, [:sid, :city] + [:name])
```

This dynamic nature is even more exemplified by Alf allowing the definition of user-defined relational operators. For instance, the documentation shows how you can add a 'safe' join. The latter allows specifying on which attributes the join must apply, projecting away the other common attributes from the right operand, that would otherwise be taken into account by Alf's (natural) join:

```try
# `on`, `left.attr_list` and `right.attr_list` are all AttrList values
# on which `&` and `-` operators are defined
def join_on(left, right, on)
  commons = left.attr_list & right.attr_list
  join(left, allbut(right, commons - on))      # join is *natural* join in Alf
end

# The part :name will be projected away, so the join applies on :city only
join_on(suppliers, parts, [:city])
```

Beyond Alf itself, I'd like a data manipulation language that would be more dynamic than SQL and even more *structured* than it. Despite its name, and even if you can compose SQL queries in a way similar to what is shown here, SQL seriously lacks lightweight and easy to use structuring mechanisms. The latter should help you *reason* about the task at hand while also raising the level of abstraction along the way, e.g. through composable user-defined relational operators.

### A few weaknesses

While Alf has been really convincing towards those goals in practice, it exposes two serious weaknesses:

* the purely functional syntax shown above quickly gets non-friendly with longer queries.
* the dynamic nature of Alf is a sharp tool and sharp tools may hurt. Said otherwise, what "compile-time" guarantees can we have on a dynamic query language like Alf?

I'll mostly discuss the first point here. I'll come back to the second one at the end of this essay.

One way to overcome the syntax issue is to assign subqueries to variables, as shown below. Even if it is the approach to use in practice with Alf in Ruby, I've always thought that doing so violates the functional spirit of the language itself (that is, if one abstracts from Alf being a Ruby DSL and take it as a language of its own).

```try
qry = join(suppliers, shipments)
qry = restrict(qry, city: "London")
qry = project(qry, [:sid, :pid, :name, :qty])
```

Another way to overcome the problem in practice is to rely on Alf's object-oriented syntax instead of the functional one (see the example below). From a language design point of view, it comes at the risk of introducing unneeded object-oriented difficulties (such as encapsulated state and/or o-o messages) into the otherwise simple functional picture of relational algebra: 

```ruby
suppliers
  .restrict(city: "London")
  .project([:sid, :name, :city])
```

So I ended up with this question: *Can I design a friendly syntax, and still provide it with a sound and simple functional semantics?*. The answer is yes.

## Relational Algebra: a friendly functional syntax

Drawing inspirations from Eve, Elixir, Haskell, Ruby, and Alf itself I've ended up with the proposal below:

```ruby
suppliers                                   suppliers
  | join shipments                            | join shipments
  | restrict @city = "London"                 | matching (parts | restrict @color = 'Red' | project [:pid])
  | project @sid, @pid, @name, @qty           | restrict @city = "London"
                                              | project @sid, @pid, @name, @qty
```

(The query transformation that brings the query at right from the one at left mimics the inclusion of a new data requirement: *From suppliers and their shipments ... yet only shipments of red parts ...*)

Contrast the query above with Alf's functional syntax and what it takes, in terms of indentation and parenthesizing, to go from the query at left to the one at right:

```ruby
project(                                    project(
  where(                                      where(
    join(shipments, suppliers),                 matching(
    city: "London"),                              join(shipments, suppliers),
  [:sid, :pid, :name, :qty])                      project(
                                                    restrict(parts, color: 'Red'),
                                                    [:pid])),
                                                city: "London"),
                                              [:sid, :pid, :name, :qty])
```
Both queries in SQL too, mostly for the record:

```sql
SELECT S.sid, SP.pid, S.name, SP.qty        SELECT S.sid, SP.pid, S.name, SP.qty
FROM suppliers S                            FROM suppliers S
  NATURAL JOIN shipments SP                   NATURAL JOIN shipments SP
WHERE S.city = 'London'                     WHERE S.city = 'London'
                                            AND SP.pid IN (
                                                 SELECT pid FROM parts 
                                                 WHERE color = 'Red' )
```

My new syntax seems to have many advantages in comparison to Alf and SQL itself:

* Not too many parentheses are required, unlike Alf's purely functional syntax,
* The proposal does not rely on variable assignment, nor does it use object-oriented confusing constructs,
* Inserting a new relational operator into an existing expression is as simple as adding a new line, as shown by the query at right,
* As illustrated too, it is still easy to embed sub-expressions; the syntax thereby nicely exposes the compositional nature of relational algebra.
* The syntax can still be given a formal functional semantics (e.g. terms of lambda calculus); in other words, it can be made precise.

## Brief overview of the semantics

What might be the semantics of the language sketch here? Let me start by removing the syntactic sugar, getting closer to Alf regarding argument values:

``` ruby
suppliers
  | join shipments
  | restrict (t -> t.city = "London")
  | project [:sid, :pid, :name, :qty]
```

In other words, `restrict` actually takes an anonymous function from tuples to Booleans as first argument. Similarly, `project` takes a list (actually a set) of attribute names. I'll make those notions more precise in the next section.

Now, let define the pipe operator `|` as left associative and of very low priority, and add the parentheses accordingly:

```ruby
(((suppliers
  | join shipments)
  | restrict (t -> t.city = "London"))
  | project [:sid, :pid, :name, :qty])
```

Let also define `|` as an infix notation for function application, that is,

```haskell
a | f  =  f a
```

(or `f(a)` if you want, even if I will not use that kind of parenthesizing here).

Before desugarizing `|`, some extra parenthesizing is required:

```ruby
(((suppliers
  | (join shipments))
  | (restrict (t -> t.city = "London")))
  | (project [:sid, :pid, :name, :qty]))
```

Then, expanding `|` yields:

```ruby
(project [:sid, :pid, :name, :qty])
  ((restrict (t -> t.city = "London"))
    ((join shipments) suppliers))
```

What does it suggest? Let take a shortened expression thanks to the following definitions:

```
attrList = [:sid, :pid, :name, :qty]
predicate = (t -> t.city = "London")
s = suppliers
sp = shipments
```

Then, you obtain the following expression:

```
(project attrList) ((restrict predicate) ((join sp) s))
```

This kind of expression has a special form, since every function abstraction takes only one argument. This is reminiscent of lambda calculus, that we might use to define the evaluation semantics of the language very precisely (I won't, at least not in this post).

## Signatures for Relational Operators

The functional expression above suggests precise signatures for the relational operators (with inspiration from Haskell this time). Let me introduce some notations first:

* let `[N]` denote the type 'set of attribute names' ; `N` will denote one of such sets, e.g. `[:sid, :name]`
* let `{H}` denote the type 'tuples with heading `H`' ; `H` will denote such heading.
* let `{{H}}` denote the type 'relations with heading `H`' ; idem
* let `X -> Y` denote the type 'functions from `X` to `Y`' ; `->` is right associative, that is, `X -> Y -> Z` means `X -> (Y -> Z)`

We can now provide signatures for the three operators used in the running example.

### Project

```haskell
project :: [N] -> {{H}} -> {{I}}
  require : N is a subset of H's attribute names
  ensure  : I = H projected on N 
```

The `project` operator takes a list of attribute names `N`. It returns a function that takes a relation with heading `H` as input and returns a relation with heading `I` as output. The `require` and `ensure` clauses must be properly formalized, but it will be the topic of another post. Roughly, they encode type constraints that must either be enforced at compile time (a good challenge here, if anyone is interested) or injected as runtime checks.

### Restrict

```haskell
restrict :: ({H} -> Boolean) -> {{H}} -> {{H}}
  require : true
  ensure  : true
```

The `restrict` operator takes as first argument a function from tuples with heading `H` to `Boolean`s. It returns another function that takes a relation with same heading `H` as input and returns yet another relation with same heading. The `require` and `ensure` clauses are trivial here. The needed constraints are implicit, through the use of the shared `H` type variable.

### Join

```haskell
join :: {{H}} -> {{I}} -> {{J}}
  require : H and I agree on the types of shared attribute names
  ensure  : J = H + I, for some + operator on headings
```

The `join` operator (binary join, in fact) takes a relation with heading `H` as input. It returns a function that takes another relation with heading `I` as input and returns yet another relation, with heading `J`. The output heading, `J` might be easily computed / constrained from inputs, using the (properly formalized) ensure clause.

Other operators might then be defined similarly to built a relationaly complete algebra. In addition, shorcuts operators can be easily defined, as in Alf:

```haskell
-- `allbut` is the reverse of project, it projects `relation` on all but
-- the attributes in `list`
-- (Let suppose that the signature is inferred.)
allbut list relation =
  relation
    | project ((attrs rel) \ list)
```

```haskell
-- `join_on` joins left and right relations on attributes in `list`. Attributes
-- shared by `left` and `right` but not in `list` are first projected away from
-- `right` (but are kept on `left` and therefore present in the result relation.)
join_on list left right =
  let commons = (attrs left) & (attrs right) in
  left
    | join (right | allbut (commons - list))
```

## Conclusion: an avenue of challenges

The post here provides an overview of what Alf aims to be, if one abstracts from the Ruby DSL. I'm actually interrested in designing a data (well, information) manipulation language that would have tuples and relations as first-class citizen. As other researchers, language designers and programmers out there, I believe that nice synergies have to be found between functional programming and the relational model towards that goal.

The kind of treatment shown here is a simple example of such synergies. Yet it yields many open questions. For instance, what semantics are we looking for exactly? Relational algebra is already well defined, so that's surely not my goal. Functional programming is well defined too of course. Yet, it seems that the language sketched here needs a mix of both to be precisely defined. It seems that the language here actually evaluates to (or generates) relational *expressions*, whose semantics can then easily be defined. But how can we make this fully precise?

Another serious challenge is to keep the dynamic nature of Alf, while providing compile-time guarantees such a type-checking. If one accepts the hybrid nature of the language, that evaluates to relational expressions not relations themselves, then it might be possible to type-check the following program, that makes use of the operator definitions above:

```haskell
suppliers
  | join_on [:city] parts
```

A related challenge, possibly a tough one, is to define type inference rules. Such rules are actually needed for type-checking, otherwise the syntax has to be extended with type anotations and I'm not sure I want that:

```haskell
  suppliers
    | restrict (t:{city: String...} -> t.city = "London")
```

In addition, the type system needs to be defined more precisely, for type inference and type checking relations to be sound and complete. I'm sure there are plenty of nice research problems to be solved there.

In conclusion, a simple idea, yet an avenue of challenges.

(If you like this post, you should probably [follow me on twitter](http://twitter.com/blambeau), star [try-alf on github](http://github.com/alf-tool/try-alf), [send me an encouragement email](mailto:blambeau@gmail.com) or hire me on your next data problem!)
