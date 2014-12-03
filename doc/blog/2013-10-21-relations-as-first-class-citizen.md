<div class="blog-post-date">2013, October 21</div>

# Relations as First-Class Citizen - A Paradigm Shift for Software/Database Interoperability

I'm happy to announce that Alf [Alf 0.15.0](https://rubygems.org/gems/alf) has
just been released and with it, this web site! I've been thinking about all of
this for many years, often as a cross-cutting concern in [my (other) research
work](http://scholar.google.be/citations?user=JsSMtA0AAAAJ&hl=en). I've been
hacking on Alf in particular during my free time for more than two years now.
I think it was time to share it in a slightly more official way than as an
(almost invisible) [open-source research
prototype](https://github.com/alf-tool) on github. Recent personal events gave
it a serious boost and a few people convinced me to give it more visibility.
So here we go.

Alf is a modern, powerful implementation of relational algebra. It brings
relational algebra where you don't necessarily expect it: in shell, in
scripting and for building complex software. Alf has an rich set of features.
Among them, it allows you to:

* Query .json, .csv, .yaml files and convert from one format to the other with
  ease,
* Query SQL databases with a sounder and more powerful query language than SQL
  itself,
* Export structured and so-called "semi-structured" query results in various
  exchange formats,
* Query multiple data sources as if they were one and only one database,
* Create database *viewpoints* (mostly read-only viewpoints for now), to
  provide your users with a true database interface while keeping them away
  from data they may not have access to,
* Enjoy a [rich set of relational operators](/doc/) and even define your own
  high-level and domain-specific ones.

Alf is very young and not all of the advanced features are stable and/or
documented. I plan to spend some time in the next weeks and months to work on
them, so stay tuned. In the mean time, you can play with Alf on this website,
install [Alf 0.15.0](https://rubygems.org/gems/alf) and start playing with it
on your own datasets and databases, [in shell](/doc/pages/alf-in-shell) or
[in ruby](/doc/pages/alf-in-ruby). I'll come with advanced material on this
blog as soon as possible, I promise.

The rest of this post explains the context of this work and why it exists in
the first place, in the form of a (very accessible) scientific paper (this
writing style is also a test, let me know what you think). The [following
section](#intro) provides a short overview of the proposed approach,
explaining the title of this blog post. We then detail Alf's proposal, first
with a [short example](#practice) illustrating the advantages compared to
existing solutions, then with [a more theoretical presentation](#theory)
covering three main questions:
[why true relational algebra?](#why-relational-algebra),
[what type system to expose?](#what-type-system), and
[why not classes and objects?](#why-not-classes-and-objects).
 [Alf's limitations and features to come](#ongoing-work) are then
briefly discussed, before [concluding](#conclusion).

<h2 id="intro">Yet another database connectivity library?</h2>

We already have [ARel](https://github.com/rails/arel),
[Sequel](http://sequel.rubyforge.org/),
[SQLAlchemy](http://www.sqlalchemy.org/), [Korma](http://www.sqlkorma.com/),
[jOOQ](http://www.jooq.org/) and probably hundreds of similar projects for
connecting to databases from code. Do we really need one more?

Well, Alf is a database connectivity library but it is first and foremost
about a proposal for a new _kind_ of software/database interoperability, or a
paradigm shift if you want. This paradigm is called **Relations as First-Class
Citizen** and it makes Alf different from existing approaches. The difference
lies in the kind of data abstraction exposed to the software developer:

* Call-level interfaces (e.g. JDBC) expose SQL query strings and database
  cursors (e.g. `java.sql.ResultSet`),
* Higher-level SQL libraries, such as [ARel](https://github.com/rails/arel),
  [Sequel](http://sequel.rubyforge.org/), and [jOOQ](http://www.jooq.org/)
  expose SQL queries as well. However, they abstract them behind abstract
  syntax trees (AST), and algebra-inspired manipulation operators.
* Object-Relational Mappers (ORMs) expose classes and objects together with
  the SQL/AST interface they generally rely on (e.g. the symbiosis between
  [ARel](https://github.com/rails/arel) and
  [ActiveRecord](http://guides.rubyonrails.org/active_record_querying.html)),
* [Alf](https://github.com/alf-tool/alf) and
  [Axiom](https://github.com/dkubb/axiom) expose _Relations_ (i.e. [sets of
  tuples](/doc/pages/relational-basics)) and relational algebra. For those
  interested, I'll discuss some differences between Alf and Axiom later in this
  blog post. In the mean time and unless stated otherwise, what is said about
  Alf applies to Axiom too.

In this blog post, I'm going to compare Alf with the second category above,
i.e. high-level SQL-driven libraries. Not because the **Relations as
First-Class Citizen** paradigm cannot be compared to, say, Object-Relational
Mapping but because, at first glance, Alf shares a lot more with those
libraries than with ORMs. First things first thus, let start looking at those
similitudes and (sometimes subtle) differences. We start with a motivating
example in the next section before moving to more theoretical arguments in the one immediately following.

<h2 id="practice">Motivating example</h2>

<i>This might appear rude or offensive, but I need to start by complaining
about existing approaches and libraries (why would I work on Alf in the first
place otherwise?). [Sequel](http://sequel.rubyforge.org/) is used in this blog
post but the situation is similar with all the libraries I mentioned
previously. I've chosen Sequel because I commonly use and actually</i> love
<i>it. No offense to be taken therefore even if I claim, in essence, that
things could be improved.</i>

My main complaint is that, despite providing [closure under
operations](http://en.wikipedia.org/wiki/Closure_(mathematics)), existing
libraries fail at providing a truly composable way of tackling data
requirements. To understand why, let me take a concrete software engineering
example on (a slighly modified version of) the [suppliers and parts
examplar](http://en.wikipedia.org/wiki/Suppliers_and_Parts_database). We'll
use the following [`suppliers`](/?src=c3VwcGxpZXJz) and
[`cities`](/?src=Y2l0aWVz) relations:

```
suppliers:                                     cities:
+------+-------+---------+--------+            +----------+----------+
| :sid | :name | :status | :city  |            | :city    | :country |
+------+-------+---------+--------+            +----------+----------+
| S1   | Smith |      20 | London |            | London   | England  |
| S2   | Jones |      10 | Paris  |            | Paris    | France   |
| S3   | Blake |      30 | Paris  |            | Athens   | Greece   |
| S4   | Clark |      20 | London |            | Brussels | Belgium  |
| S5   | Adams |      30 | Athens |            +----------+----------+
+------+-------+---------+--------+
```

Let suppose that the suppliers themselves are the software users and that the
following requirements must be met by the particular inferface showing the
list of suppliers to the current user:

1. A supplier may only see information about the suppliers located in the same
   city than himself.
2. The supplier's `status` is sensitive and should not be displayed.
3. The country name must be displayed together with the supplier's city

In terms of the query to be built, those requirements involve a restriction
(`same city as`), a selection (`no status`) and a join (`with country name`).
Suppose you are supplier `S3`, the list of suppliers you see [looks like
this](/?src=cmVxdWVzdGVyID0gIlMzIgpqb2luKGFsbGJ1dChtYXRjaGluZyhzdXBwbGllcnMsIHByb2plY3QocmVzdHJpY3Qoc3VwcGxpZXJzLCBzaWQ6IHJlcXVlc3RlciksIFs6Y2l0eV0pKSwgWzpzdGF0dXNdKSwgY2l0aWVzKQ):

```
+------+-------+-------+----------+
| :sid | :name | :city | :country |
+------+-------+-------+----------+
| S2   | Jones | Paris | France   |
| S3   | Blake | Paris | France   |
+------+-------+-------+----------+
```

<h3 id="struggling">Struggling with reuse and separation of concerns</h3>

Writting a monolithic query is rather straightforward. Using [Sequel](http://sequel.rubyforge.org/) for instance:

```
requester_city = ... # from context (authenticated user)

DB[:suppliers]
  .natural_join(:cities)
  .select(:sid, :name, :city, :country)
  .where(:city => requester_city)

# => SELECT sid, name, city, country
#    FROM suppliers NATURAL JOIN cities
#    WHERE (city = ...)
```

In software involving complex requirements, relying on monolithic queries is
unfortunately not always possible and/or desirable (otherwise, creating
database views would simply be enough). Two main reasons explain this:

* The same requirements tend to apply to various and independent software
  features. For instance, the first two requirements above might apply
  _everytime_ a list of suppliers is shown, while the third one might not.
  Complex requirements generally call for a design that achieves both
  separation of concerns and reuse.
* Complex software also involves context-dependent requirements. For instance,
  the first requirement above might be relaxed for administrators (say,
  suppliers with status greater than 30).

This explains why connectivity libraries and their SQL utilities exist in the
first place: because of the need to _build_ queries, often at runtime and
according to some context. There is a desperate need for more support for this
in DBMSs themselves. In the mean time, developers rely on the ability of host
programming languages and third-party libraries.

Back to our example above, what about the following "design"?

```
# Meet 1) and 2) together as a utility method: separation of concerns
def suppliers_in(city)
  DB[:suppliers]
    .select(:sid, :name, :city)
    .where(:city => city)
end

# Meet 3) as a utility method: separation of concerns
def with_country(operand)
  operand.natural_join(:cities)
end

# Meet them all: composition and reuse
requester_city = ... # from context
with_country(suppliers_in(requester_city))
```

Wrong. The original, and correct, SQL query was:

```sql
-- Give the id, name, city and country of every supplier located in city ...
SELECT sid, name, city, country
FROM suppliers NATURAL JOIN cities
WHERE (city = ...)
```

The new one seems smiliar, but is wrong. As shown below, we lost the country
in the process:

```sql
-- Give the id, name and city of every supplier located in city ..., provided
-- the city is known in `cities`
SELECT sid, name, city
FROM suppliers NATURAL JOIN cities
WHERE (city = ...)
```

What happened? In short, `Sequel`'s join does not correspond to a _algebraic_
join of its operands. Instead, its specification looks like "adds a term to
the `SQL` query's `FROM` clause", whose data semantics is far from obvious
(here you can blame `SQL` itself). Observe in particular that the following
algebraic equivalence does not hold in `Sequel`, preventing us from using the
design above:

```
suppliers
  .natural_join(cities)
  .select(:sid, :name, :city, :country)
<=!=>
suppliers
  .select(:sid, :name, :city)
  .natural_join(cities.select(:city, :country))
```

Join is a striking example of the problem at hand, but others exist that
involve different operators. Let me insist on something: the same is true with
[ARel](https://github.com/rails/arel), [Sequel](http://sequel.rubyforge.org/),
[SQLAlchemy](http://www.sqlalchemy.org/), [Korma](http://www.sqlkorma.com/),
[jOOQ](http://www.jooq.org/) to cite a few. The fact is:

* SQL has not been designed with composition and separation of concerns in
  mind,
* Avoiding strong coupling between subqueries tends to be very difficult in
  practice,
* Coupling hurts separation of concerns and software design.

To be fair... There _is_ a way to use `SQL` (and, sometimes, those libraries)
so as to avoid the problem described here. It amounts at using `SQL` in a
purely algebraic way. Unfortunately, that way is not idiomatic and leads to
complex SQL queries, that may have bad execution plans (at least in major
open-source DBMSs). In the example at hand, using Sequel's `from_self` in a
systematic way (e.g. on every reusable piece) is safe from the point of view
of composition and reuse:

```
def suppliers_in(city)
  DB[:suppliers]
    .select(:sid, :name, :city)
    .where(:city => city)
    .from_self
end

def with_country(operand)
  operand
    .natural_join(:cities)
    .from_self
end

requester_city = ... # from context
with_country(suppliers_in(requester_city))

# SELECT * FROM (
#   SELECT * FROM (
#     SELECT sid, name, city FROM suppliers
#     WHERE (city = ...)
#   ) AS 't1'
#   NATURAL JOIN cities
# ) AS 't1'
```

The complete recipe for using SQL in such a "safe" way is more complex, of
course, but possible. I won't provide the details in this blog post, let me
know if a dedicated one is welcome. For now, let see how our new paradigm
helps.

### Relation Algebra at the rescue...

Libraries like Sequel and Arel offer closure under operations, meaning that
you can chain operator invocations (e.g.
`operand.select(...).where(...).where(...)`). Subtly enough, that does not
make them exposing an algebra, because SQL is not itself a pure relational
algebra (see [later](#why-relational-algebra)) and these libraries do espouse
SQL in a rather faithful way.

In contrast, the **Relations as First-Class Citizen** paradigm aims at
providing an interface that is _designed for_ composition and reuse. To
achieve this, Alf takes some distance from SQL and exposes a true relational
algebra instead, inspired from <a
href="http://en.wikipedia.org/wiki/D_(data_language_specification)"
target="_blank"><b>Tutorial D</b></a>. This makes a real difference, even if
subtle. To convince yourself, I invite you to use
<a href="/?src=cmVxdWVzdGVyX2NpdHkgPSAnUGFyaXMnCnNvbHV0aW9uID0gc3VwcGxpZXJzCgojIDEpLiBBIHN1cHBsaWVyIG1heSBvbmx5IHNlZSBpbmZvcm1hdGlvbiBhYm91dCB0aGUgc3VwcGxpZXJzIGxvY2F0ZWQKIyBpbiB0aGUgc2FtZSBjaXR5IHRoYW4gaGltc2VsZi4Kc29sdXRpb24gPSByZXN0cmljdChzb2x1dGlvbiwgY2l0eTogcmVxdWVzdGVyX2NpdHkpCgojIDIpIFRoZSBzdXBwbGllcidzIGBzdGF0dXNgIGlzIHNlbnNpdGl2ZSBhbmQgc2hvdWxkIG5vdCBiZSBkaXNwbGF5ZWQuCnNvbHV0aW9uID0gYWxsYnV0KHNvbHV0aW9uLCBbOnN0YXR1c10pCgojIDMpLiBUaGUgY291bnRyeSBuYW1lIG11c3QgYmUgZGlzcGxheWVkIHRvZ2V0aGVyIHdpdGggdGhlIHN1cHBsaWVyJ3MgY2l0eS4Kc29sdXRpb24gPSBqb2luKHNvbHV0aW9uLCBjaXRpZXMp">Alf's Try console</a>
to check that the example below works as expected. As shown, the three
requirements of our case study can be incorporated incrementally thanks to the
true composition mechanism offered by an algebra. Commenting a line amounts at
ignoring the corresponding requirement:

```try
requester_city = 'Paris'
solution = suppliers

# 1). A supplier may only see information about the suppliers located
# in the same city than himself.
solution = restrict(solution, city: requester_city)

# 2) The supplier's `status` is sensitive and should not be displayed.
solution = allbut(solution, [:status])

# 3). The country name must be displayed together with the supplier's city.
solution = join(solution, cities)
```

To better understand why it works, observe that in Alf, the equivalence
mentionned in the previous section holds. That is, the two following queries
are equivalent, something that you can check by yourself using the console:

```try
project(
  join(suppliers, cities),
  [:sid, :name, :city, :country])
```

and

```try
join(
  project(suppliers, [:sid, :name, :city]),
  project(cities, [:city, :country]))
```

Interestingly enough, this kind of equivalences may be used for query
optimization and smart SQL compilation. I invite you to check the `Optimizer`
and `Query plan` tabs of the console on both queries. The generated SQL query
is the same in both cases. Alf tries very hard to keep generated SQL as simple
as possible, in the hope to avoid ugly query plans in the SQL DBMS itself:

```sql
SELECT t1.sid AS sid, t1.name AS name, t1.city AS city, t2.country AS country
FROM suppliers AS t1
INNER JOIN cities AS t2 ON (t1.city = t2.city)
```

### ... plus extra

What if the `cities` tuples (that does not actually exists in the original
suppliers and parts examplar), come from somewhere else? A .csv file, another
database or whatever datasource?

```try
requester_city = 'Paris'
solution = suppliers

# 1) and 2) above, but inline
solution = allbut(restrict(solution, city: requester_city), [:status])

# Might be Relation.load('cities.csv'); we use a literal for execution on try-alf.org
third_party_cities = Relation([
  {city: 'London', country: 'England'},
  {city: 'Paris',  country: 'France'}
])
solution = join(solution, third_party_cities)
```

The example above shows that, in addition to the advantages previously cited,
the composition mechanism of relational algebra, unlike SQL queries, makes few
assumptions about where the operands come from, by very nature. In a sense,
the **Relations as First-class citizen** can be seen as a purely functional
kind of programming where immutable values are relations and functions are
relational operators. This kind of comparison is not new. It was already
suggested several years ago in Ben Moseley's famous <a
href="http://shaffner.us/cs/papers/tarpit.pdf">Out of the Tar Pit</a> essay.
Alf contributes an example of the general framework outlined there.

<h2 id="theory">More about the paradigm and its motivation</h2>

Moving from SQL to a relational algebra is one of the changes underlying the
**Relations as First-Class Citizen** paradigm for software/database
interoperability, but it is not the only one and maybe not the most important
(?). The following subsections detail the paradigm further and provides
motivations and theoretical arguments. They address the three following
questions:

* [Why relational algebra](#why-relational-algebra) is a better choice than
  relational calculus for developing software?
* [What type system](#what-type-system) do we want to expose to software developers? SQL's one or the host language's?
* [Why _relations_](#why-not-classes-and-objects) instead of traditional _classes and objects_ for structural concepts?

<h3 id="why-relational-algebra">From Relational Calculus (SQL) to Relational Algebra</h3>

In my opinion, the fact that SQL is used daily by software developers is the
result of an historical mistake, or a misfortune at least. Indeed, SQL has
been invented in the database community at a time where it was envisioned that
_end users_ would query relational databases. This is more than 40 years ago.
At that time, the nature of software, software engineering, requirements
engineering and human-software interactions were not understood as they are
today.

With this envisioned reality in mind, SQL has been chosen nearer to (tuple)
relational calculus than to relational algebra (for the sake of accuracy, it
is a strange mix of both; yet another obscure historical reasons explain
this). For a good understanding of the discussion here, it is important to
understand the difference in nature between a calculus and an algebra:

* In a calculus, what you describe is the problem to solve, not how to solve
  it. Hence the `from ... select ... such that ...` declarative kind of
  question you ask to an SQL DBMS:

      ```sql
      -- Get the cities where at least one supplier is located, provided
      -- at least one part is located there too.
      SELECT DISTINCT city FROM suppliers AS s
      WHERE EXISTS (
        SELECT city FROM parts AS p
        WHERE s.city = p.city
      )
      ```

* In contrast, with an algebra you manipulate symbols, that denote _values_,
  through a predefined set of operators. You use those operators to _build_
  or _reach_ the solution to your problem:

      ```try
      # Get the cities where at least one supplier is located, provided
      # at least one part is located there too.
      cities_from_suppliers = project(suppliers, [:city])
      cities_from_parts     = project(parts, [:city])
      intersect(cities_from_suppliers, cities_from_parts)
      ```

As shown by the example above, a calculus is more declarative than an algebra.
In other words, the latter looks more like an algorithm. This explains why
SQL, probably the most idiomatic _end-user_ query language ever, has been
designed as a calculus. As an end-user, when you (manually) query a database
you generally know the problem at hand. Therefore, you welcome a declarative
language since it allows you to express that problem while leaving to the
underlying engine the job of finding the solution instead of having to
describe the algorithm to compute it. _This_ is what SQL offers to its users.

Now, I suppose it is not too risky to claim that, today, a large majority of
interactions with databases is done by software components, possibly on behalf
of their end users, and generally in accordance to specific requirements. The
_actual_ users of (relational) databases are not end-users after all, but
software components and, indirectly, their developers.

Yet, developping software is of a very different nature than querying
databases. As a software engineer, you generally don't have one single problem
at hand. Instead, you have a set of problems called _requirements_ and you
find a design that allows meeting them all (cfr. [the previous
section](#practice) for an example). One of the most effective strategies
available in the software engineer toolset is _divide and conquer_. A modular
design, for example, helps achieving a good separation of concerns with
respect to those requirements while ensuring that the software behaves as
expected when all modules are put together.

While the declarative style of programming of SQL is very nice for solving
very specific and well isolated sub-problems in your requirements & design
space, it is of almost no aid for putting the architectural pieces together.
Yet, putting the pieces together is something software engineers do every
single day. And so is writing algorithms. Exposing a relational algebra
therefore appears more natural when it comes to software development, and when
it comes to _manipulating_ data vs. _querying_ database. To be fair, libraries
such as [ARel](https://github.com/rails/arel),
[Sequel](http://sequel.rubyforge.org/), and [jOOQ](http://www.jooq.org/)
already show the way: they provide an API that is closer to relational
algebra than relational calculus. [Alf](https://github.com/alf-tool/alf) and
[Axiom](https://github.com/dkubb/axiom) simply go further this path by
abstracting from SQL and choosing a sound algebra known as <a
href="http://en.wikipedia.org/wiki/D_(data_language_specification)"
target="_blank"><b>Tutorial D</b></a> as a better inspiration than SQL towards
the same objective.

The **Relations as First-Class Citizen** paradigm makes all of this more sound
in my opinion, because putting _relations_ together is much easier than
putting _SQL queries_ together (cfr. [the _join_ example](#struggling) in the
previous section). The semantics of "putting together" is more straightforward
in the former case, that's all. An algebra *is* about providing operators for
putting operands together, a calculus simply is not. Approaches such as Alf's
is no less expressive, quite the contrary. For instance, expressing a SQL
`WHERE NOT EXISTS` is kind of [a
nightmare](http://stackoverflow.com/questions/7152424/rails-3-arel-for-not-exists)
with existing approaches, and almost impossible to do in a modular way due to
the coupling between the main query and the sub-query:

```
# Show suppliers that supply no part at all (Sequel)
DB[:suppliers___s].where(~DB[:shipments___sp].where(Sequel.qualify(:sp, :sid) => (Sequel.qualify(:s, :sid))).exists)
```

It is dead simple in Alf (and here, you can thank <a
href="http://en.wikipedia.org/wiki/D_(data_language_specification)"
target="_blank"><b>Tutorial D</b></a>, where this operator comes from):

```try
# Show suppliers that supply no part at all (Alf)
not_matching(suppliers, shipments)
```

Now, relational calculus and relation algebra are known to be equivalent in
expressive power. This is what allows Alf to compile queries in the second
form above to something similar to the former one and to send it to an
underlying SQL DBMS. The feature is limited by the ability to reconcile the
Ruby and SQL type systems though, something I will discuss in the next
section.

<h3 id="what-type-system">From SQL's to Host's Type System</h3>

There is another very important change I have not discussed so far regarding
the proposed **Relations as First-Class Citizen** paradigm. In essence, it is
a challenging proposal (from an implementation point of view at least): _why
not abstracting from SQL completely?_

_Aside: this section applies to Alf but, as far as I know, not to Axiom._

Indeed, almost all approaches (even ORMs) do actually espouse SQL in a very
rigid way. An obvious example is that the developer is almost never allowed to
express filtering conditions or to perform computations that are not supported
by SQL in the first place. It is unfortunate, because SQL's type system is
old, and poor (few support for user-defined types, for instance). How about
providing a query interface that actually espouse the host type system, i.e.
the one of the host programming language (here, Ruby)?

Want to express a filtering condition involving a ruby regular expression? No
problem:

```try
# Get suppliers whose name contains a 'J' or a 'B'
restrict(suppliers, ->(t){ t.name =~ /J|B/ })
```

Want to compute an array-valued attribute (or even use you own user-defined
data type/class)? No problem:

```try
# Get suppliers and the letters of their name in uppercase
extend(suppliers, letters: ->(t){ t.name.upcase.chars.to_a })
```

Want to group tuples as sub-relations? There is even an operator for that:

```try
# Get suppliers grouped by city
group(suppliers, [:sid, :name, :status], :suppliers)
```

This might look at simply providing a consistent interface for working with
relations. Absolutely, that's the point. You can mix everything, composing
queries in the idiomatic way. In the example below, Alf compiles the 'Paris'
restriction to SQL while it computes the 'letters' extension itself (see the
optimizer and query plans), even if the extension comes _before_ the
restriction:

```try
rel = extend(suppliers, letters: ->(t){ t.name.upcase.chars.to_a })
rel = restrict(rel, city: 'Paris')
```

Now think about it. This amounts at _abstracting_ from SQL and letting
developers think in terms of their _usual_ type system. While powerful, this
is very challenging (but fun) in practice for the implementer (i.e. for me)
and comes at a cost (for you). There are drawbacks and limitations that you
must be aware of (I'll come back to this point in the next section). That
means that you can't abstract from reality entirely after all, as often with
abstractions, but yet more than with existing approaches in my opinion.

<h3 id="why-not-classes-and-objects">From One-At-a-Time to Set-At-a-Time</h3>

This point is very important, since it introduces a significant difference
with Object-Relational Mapping. I haven't talked much about ORM so far, but
it's true that **Relations as First-Class Citizen** is better compared to
**Object-Relational Mapping** (ORM) than to libraries such as `Sequel`. Both
are paradigms that present data to the software in a particular way, and
provide an abstraction mechanism _above_ SQL. (I take this opportunity to put
a bit of fairness back into the picture. This is especially important for me
since Alf itself currently relies on `Sequel` to generate cross-DBMS SQL code
in a very easy way.)

Object-Relational Mapping relies on the availability of an Object Model, that
aims at capturing the (structual) domain. Doing so is one interpretation of what
[Domain Driven Design](http://books.google.be/books?id=hHBf4YxMnWMC&printsec=frontcover&source=gbs_ge_summary_r&cad=0#v=onepage&q&f=false)
(DDD) is about, more accurately one implementation strategy of DDD. I'm not
convinced it's the good one, but it's definitely one of them. There are at
least two reasons why I'm not convinced.

First, modeling the (data) domain is certainly not the same as designing a
software for meeting requirements in that domain (whatever that means). The
fact that you've drawn O-O diagrams (even if it's in your head) capturing the
domain entities, their relationships and interactions is not sufficient for
stating that the software implementation must be a copy-paste of those
diagrams. Most of the time, the software _supports_ the domain; it does rarely
_implement_ or _simulate_ it. Models are there to guide your _understanding_
of the domain, not to _be_ the implementation of your requirements. Subtle
difference (abstract one, I'm affraid), but important.

The second reason is more directly relevant to the proposed paradigm and Alf.
Suppose a `Supplier` class in your O-O software. What does that class capture?
Well, from a modeling point of view it captures the fact that `supplier` is
a relevant concept/entity in the domain. From the software point of view,
it captures an irrelevant set, and lots of individuals of (marginal?) interest:

* The `Supplier` class captures the set of all possible suppliers, that is,
  all possible supplier instances that you can represent in software memory by
  invoking the class constructor. Observe that you can't do anything relevant
  with this set with respect to your actual requirements, except maybe
  "selecting" a particular individual.
* Those individuals are of course not the _real_ suppliers, but only
  _information about_ them or a _representation of_ them in the software. I
  invite you to read [a previous writing of
  mine](http://www.revision-zero.org/orm-haters-do-get-it) to understand why I
  think that manipulating information through individuals is just wrong.

I won't repeat those arguments here. Let me instead simply state a few
requirements in our hypothetic suppliers and parts software, while
highlighting relevant parts for the discussion at hand:

* A supplier may only see information about **the suppliers located in the same
  city than himself**,
* The GUI shall display **relevant information about the supplier such as her
  name, city and country**.
* The GUI shall never expose **supplier statuses**, except to
  **administrators**, that is, **suppliers with a status greater than 30**.
* The software should periodically send an email to **all suppliers who supply
  less than 5 parts** to ...
* The administration interface shall display **performance indicators** such as
  the **number of registered suppliers per city**, ...
* and so on.

Hence the following question. Why does our source code provide such a huge
visibility to completely irrelevant sets, e.g. the `Supplier` class, instead
of promoting those relevant sets above as first class citizen? Hence the name
of the paradigm, **Relations as First-Class Citizen**, because relations
better capture those sets than O-O classes:

```try
extend(DEE,
  # the suppliers located in the same city than himself (say S3)
  visible: ->(t){
    matching(suppliers, project(restrict(suppliers, sid: 'S3'), [:city])) 
  },
  # administrators, i.e. suppliers with a status greater than 30
  administrators: ->(t){
    restrict(suppliers, gte(:status, 30))
  },
  # registered suppliers
  registered: ->(t){
    suppliers
  })
```

(Note that the example above does not aim at illustrating an actual
user-friendly syntax or idiomatic way of implementing the kind of features I'm
discussing here. It shows, in contrast, that all those relations can be
captured rather easily, even all at once; try it).

ORMs such as Active Record provide so-called
<a target="_blank" href="http://guides.rubyonrails.org/active_record_querying.html#scopes">scopes</a>
that may be argued providing what I ask here (possibly with a better syntax,
by the way):

```
class Supplier < ActiveRecord::Base
  scope :administrator, -> { where("status > 30") }
end
```

Two main important differences exist, though:

* First, observe that in Active Record, `Supplier` and
  `Supplier.administrator` do not denote similar things. The first one is a
  `Class`, the second is an `ActiveRecord::Relation` and you can't substitute
  one for the other. In addition, scopes are subordinated to classes, making
  them second-class, not first-class citizen.
* Second, scopes do not allow deriving new first-class concepts. They mostly
  allow filtering existing ones (loosely speaking). For instance, you'll have
  a hard time trying to promote the concept below as first-class with scopes.
  Indeed, it would require creating "derived classes", whatever this is
  supposed to mean in practice:

      ```try
      # performance indicators, e.g. registered suppliers per city
      indicators = summarize(suppliers, [:city], nb: count())

      # first-class means you can use it as any other concept
      restrict(indicators, gt(:nb, 1))
      ```

To summarize (sorry if it seems offensive, I'd better like to be
thought-provoking instead): ORMs promote irrelevant sets as first-class and a
subset of relevant ones as second-class, subordinated to the former. Isn't
that _very_ strange? In addition, ORMs promote a "design around structural
concepts" kind of programming style, where good object-oriented design focuses
on behaviors instead.

Now, Alf provides a good foundation for **Relations as First-Class Citizen**,
but it does not completely reach that point so far. Indeed, it provides a way
to compute any relation and use it consistently. To implement the paradigm
completely, however, it would also need to provide a way to 'promote' the
relations that makes more sense in the domain as _special_ citizen in the
software design. I'll say a word about domain-specific relational operators
and database viewpoints in the next section, which are good attempts to reach
this but require more work.

<h2 id="ongoing-work">Limitations and ongoing work</h2>

The approach proposed here opens an avenue for further optimization,
experimentation and research. I close this blog post with an overview of my
own ongoing work in this area (which are all subjects I will be talking about
here in the near future). I also draw the reader's attention on Alf's current
limitations.

### Towards high-level, domain-specific relational operators

The closure property of relational algebra opens the ability to define new
relational operators in a very simple way, provided they are shortcuts over
longer expressions. Alf comes with such a facility, as illustrated below:

```try
# It relation `test` contains at least one tuple return `then_relation`,
# otherwise return `else_relation`
def ite(test, then_relation, else_relation)
  union(
    matching(then_relation, project(test, [])),
    not_matching(else_relation, project(test, [])))
end

# It there are at least one Red part, show suppliers in London, otherwise
# show suppliers in Paris
ite(
  restrict(parts, color: 'Red'),
  restrict(suppliers, city: 'London'),
  restrict(suppliers, city: 'Paris'))
```

While the example above is contrived, our experience suggests that the `ite`
relational operator proves very useful in practice when dealing with complex
data visibility and privacy requirements. Interesting enough, you can check
that the compilation involves only one SQL query sent to the underlying DBMS,
resulting in important performance improvements compared to other approaches
relying on an `if/then/else` statement in the host language (especially when
the latter is much slower than the DBMS engine itself, e.g. Ruby vs. a DBMS
engine implemented in C).

Similarly, even when involving complex data types and collections, most query
plans involve a _constant_ number of SQL queries, avoiding the 'N+1 queries'
trap [infamously
known](http://stackoverflow.com/questions/97197/what-is-the-n1-selects-issue)
with Object-Relational Mappers:

```try
join(suppliers, group(join(shipments, parts), [:sid], :supplied_parts, allbut: true))
```

Alf already has a few high-level operators such as [matching](/doc/api/matching)
or [page](/doc/api/page). The next release should include a few others currently
evaluated on case studies: `ite`, `image`, `abstract`, `dive`, `quota`, etc.

### Database viewpoints

The closure property of relational algebra also opens the ability to define
composable database viewpoints. Viewpoints provide a very effective
abstraction mechanism for implementing complex security/privacy requirements,
as well as providing context-aware database interfaces.

Without entering the details here, the following example illustrates the
approach by hacking on Ruby's `super` mechanism. Suppose we want to provide a
database viewpoint on suppliers and parts located in London:

```try
# Start of the viewpoint
def suppliers
  restrict(super, city: 'London')
end
def parts
  restrict(super, city: 'London')
end
def shipments
  # restore foreign keys given the previous restrictions
  matching(matching(super, parts), suppliers)
end
# End of the viewpoint

# Query as usual. This is entirely transparent.
# Check it yourself, supplier S2 no longer exists in this viewpoint.
restrict(shipments, sid: 'S1')
```

Database viewpoints are currently read-only in Alf. I intentionnally left the
question of database updates aside in this blog post. Alf comes only with a
very experimental interface for updates (cfr. [Alf in Ruby](/doc/pages/alf-in-ruby))
but a lot of work is still needed in this area.

### Reconciling heterogeneous type systems

As already suggested, abstracting from SQL is challenging for the implementer.
More specifically, abstracting from SQL *and* guaranteeing soundness and
efficiency at the same time are conflicting requirements. Alf has a smart
compiler that delegates to underlying engines what can be delegated, but the
explicit use of the host type system is a showstopper during compilation. To
better understand this, consider the following query:

```try
restrict(
  extend(suppliers, uppercased: ->(t){ t.name.upcase }),
  city: 'Paris', uppercased: 'JONES')
```

If you take a look at the query plan, you'll observe that the `restrict`
invocation is only partially compiled to SQL. The `uppercased` attribute is
computed by Alf in Ruby and cannot be translated back to the SQL engine. This
has serious performance implications, of course. As of current Alf version,
this is the case as soon as you use a ruby block (e.g. `->(t){ ... }`).

All other approaches I'm aware of either have a similar problem or forbid
such queries in the first place (and are hence less expressive). This calls
for further symbiosis and interoperability between heterogeneous type systems
(SQL and Ruby in the present case).

<h2 id="conclusion">Conclusion</h2>

Arrived here? Kudos. To summarize, I'm convinced that **Relations as
First-class citizen** provides better abstractions than existing approaches
for software-database interoperability, or more generally, for handling the
data manipulation subset of our software engineering requirements. In
particular, I hope to have shown how current database connectivity approaches
hurt separation of concerns and reuse (more generally, software design) and
why favoring pure relational algebra over (idiomatic) SQL helps avoiding the
trap.

As I've discussed, Alf itself needs more work to truly embrace the paradigm,
as that goes further that simply providing an algebraic query language. Stay
tuned, I'll provide more material and writings about how to use Alf in more
complex software (such as the viewpoints stuff). In the mean time, any
question or contribution (of any kind) can be adressed by sending an email to
Bernard Lambeau (see the [About](/about/) page; I'm easily found on the
Internet too). I'm currently looking for contributors both in the academics
and in the industrial world for discussing, enhancing, testing and evaluating
the approach, don't hesitate to contact me by email.

## Acknowledgements

I'd like to thank Sergio C., Erwin S., Enrico S., David L., Magnus H., Kim M.
and Louis L. for their feedback and comments on earlier versions of this blog
post.
