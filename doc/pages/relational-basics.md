# Relational basics

This page describes the necessary background on relational theory to
understand Alf. Note that it only covers the concepts needed to understand the
relational *algebra*; that is, nothing is said about database schemas, normal
forms, transactions, ACID properties, and so on. Refer to standard database
literature for those.

The background given below is a rephrasing of what can be found in *The Third
Manifesto* (TTM), by Hugh Darwen and C.J. Date. See
[www.thethirdmanifesto.com](http://www.thethirdmanifesto.com) or [the TTM
book](http://www.amazon.com/Databases-Types-Relational-Model-3rd/dp/0321399420).

## A theory of types

To understand what relational algebra is about, we need to briefly review a
few concepts about types. Forget about object-oriented programming for a
moment (if you are a developer) and examine the following definitions:

* A *type* is a (finite) **set** of values. A *subtype* is a subset. Sets are
  **not ordered** and have **no duplicates**.
* A *value* is an element of a type. We say that the value *belongs to* the
  type.
* A value is **immutable**, intrinsically **typed**, has no localization in
  time and space, and can be of arbitrary complexity.
* A type is always accompanied with an equality operator, say `==`, that
  allows checking if two of its elements actually denote the same value. The
  notion of 'duplicate' precisely relies on this operator in an obvious way.

Oh! and,

* NULL is **not** a value. Precisely, ''treating NULL as a value'' on one side
  and ''keeping a theory simple enough to be of any practical yet sound use''
  on the other side are conflictual requirements. Therefore, here, NULL is not
  a value.

### A few examples

The simplest scalar types are well known: 

>> * (the set of) Boolean(s), Integer(s), Decimal(s), String(s), ...

There are others, of course: 

>> * (the set of) Color(s), Size(s), Weight(s), Range(s), Coordinate(s), ... 

And even a few that people don't always expect to be types: 

>> * (the set of) List(s), Set(s), Tree(s), Graph(s), ...

Roughly, surrounding a set of immutable elements for which an equality
operator makes sense *is* defining a type. Implementing it is another story,
of course.

## Tuples and Relations

Tuples and relations are values as well. In contrast to integers or strings
however, tuples and relations are not scalar; they have an internal
''structure''. Apart from that, they are values and they have a type. Let's
have a closer look at that.

### Tuple

* A *tuple* is a set of attribute (name, value) pairs. It is such that no two
  pairs have the same name.
* A tuple being a set, it is not particularly ordered.
* A tuple being a value, it is immutable.

We will denote tuple literals as follows (we assume that a Color type exists):

```
# The product whose id is 'P1',
#  * is named 'Nut', 
#  * has a color denoted by 'red', and 
#  * is known to be heavy.
Tuple(pid: 'P1', name: 'Nut', color: Color('red'), heavy: true)
```

The type of a tuple is simply defined in terms of its heading. A *heading* is
defined as a set of attribute (name, type name) pairs. For example, the
heading of the tuple show above is:

```
Heading(pid: String, name: String, color: Color, heavy: Boolean)
```

### Relation

* A *relation* is a set of tuples of same heading
* A relation being a set, it is not particularly ordered and does not have
  duplicates.
* A relation being a value, it is immutable.

We will denote relation literals as follows:

```
Relation([
  Tuple(pid: 'P1', name: 'Nut',   color: Color('red'),   heavy: true),
  Tuple(pid: 'P2', name: 'Bolt',  color: Color('green'), heavy: false),
  Tuple(pid: 'P3', name: 'Screw', color: Color('blue'),  heavy: false)
])
```

The type of a relation is simply defined in terms of its heading. For example,
the heading of the relation show above is:

```
Heading(pid: String, name: String, color: Color, heavy: Boolean)
```

## A few consequences

The following list of bullets are logical consequences of the definitions
above. Alf considers them as part of its specification; if you see Alf
behaving differently from what is being said here, then it's a bug or a
limitation of the current version... for which patches are welcome!

* Tuples and relations may contain values of any complexity, provided that the
  corresponding type is consistent with the theory of types stated above.
* In particular, tuples and relations may contain... tuples and relations.

The following points are other logical consequences of the definitions above.
Alf considers them as pre-conditions of all relational operators, without
necessarily enforcing them:

* All tuples that are member of a relation must have the same "structure",
  precisely, the same heading than the relation itself
* Tuples and relations never contain NULL
* No left-right ordering of attributes applies to tuples and relations
* No tuple ordering applies to relations

That said, Alf does however provide a few facilities that make it more
comfortable for the user to deal with any deviations from the theory stated
here, as they might occur in any SQL product(s) you might be using as a data
source.

## Relational algebra

Relational algebra is to relations what elementary algebra is to numbers and
quantities in formulae and equations. Consider the following elementary
formula:

```
z = 2 * (x + y)
```

Evaluating this formula with `x = 5` and `y = 3` yields a value for `z`:

```
16 = 2 * (5 + 3)
```

Thanks to known properties of the operators, like associativity or
commutativity, formulae can be manipulated. For example, the formula above can
be rewritten into the following equivalent form:

```
z = (2 * x) +  (2 * y) 
```

Relational algebra is similar, but applies to relations. For example:

```try
#  Who are supppliers located in London or in Paris?
union(
  restrict(suppliers, city: 'Paris'),
  restrict(suppliers, city: 'London'))
```

Can be rephrased/rewritten as

```try
restrict(suppliers, eq(:city, 'Paris') | eq(:city, 'London'))
```

This is kind or rewriting is of particular importance for query optimization,
but that's far beyond the basics!
