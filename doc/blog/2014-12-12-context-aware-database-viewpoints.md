# Context-aware Database Viewpoints

Viewpoints are a concept that I have only mentionned in passing in [try-alf's first post](/blog/2013-10-21-relations-as-first-class-citizen). They certainly deserve more thoughts: while very simple you'll be amazed by their power. In short, viewpoints are to databases (variables) what views are to relations (variables). If the last sentence sounds cryptic, just read on! To keep this post self-contained, I need to start with some basic material on views before moving on to context-awareness and database viewpoints. A general comment before starting: don't get abused by the taste of triviality; simplicity, sometimes, is that simple.

## Views

If you have read previous posts here or played with Alf by yourself, you know try-alf's main message now: relational algebra is a software engineer's best friend. Relational algebra is very simple yet immensely powerful, as a simple example illustrates. Let start with some relations:

```
suppliers                               shipments
+------+-------+---------+--------+     +------+------+------+
| :sid | :name | :status | :city  |     | :sid | :pid | :qty |
+------+-------+---------+--------+     +------+------+------+
| S1   | Smith |      20 | London |     | S1   | P1   |  300 |
| S2   | Jones |      10 | Paris  |     | S1   | P2   |  200 |
| S3   | Blake |      30 | Paris  |     | S1   | P3   |  400 |
| S4   | Clark |      20 | London |     | S1   | P4   |  200 |
| S5   | Adams |      30 | Athens |     | S1   | P5   |  100 |
+------+-------+---------+--------+     ...
                                        | S4   | P5   |  400 |
parts                                   +------+------+------+
+------+-------+--------+---------+--------+
| :pid | :name | :color | :weight | :city  |
+------+-------+--------+---------+--------+
| P1   | Nut   | Red    |  12.000 | London |
| P2   | Bolt  | Green  |  17.000 | Paris  |
| P3   | Screw | Blue   |  17.000 | Oslo   |
| P4   | Screw | Red    |  14.000 | London |
| P5   | Cam   | Blue   |  12.000 | Paris  |
| P6   | Cog   | Red    |  19.000 | London |
+------+-------+--------+---------+--------+

```

Relational algebra lets you "manipulate" those relations with operators (`restrict`, `join`, `group`, etc.) in a similar way to "manipulating" numbers through arithmetic operators (`+`, `-`, `*`, etc.). For instance, the following Alf expression:

```try
# London suppliers with their shipments
group(
  join(
    restrict(suppliers, city: "London"),
    shipments),
  [:pid, :qty], :shipped)  
```

Evaluates to:

```
+------+-------+---------+--------+-----------------+
| :sid | :name | :status | :city  | :shipped        |
+------+-------+---------+--------+-----------------+
| S1   | Smith |      20 | London | +------+------+ |
|      |       |         |        | | :pid | :qty | |
|      |       |         |        | +------+------+ |
|      |       |         |        | | P1   |  300 | |
|      |       |         |        | | P2   |  200 | |
|      |       |         |        | | P3   |  400 | |
|      |       |         |        | | P4   |  200 | |
|      |       |         |        | | P5   |  100 | |
|      |       |         |        | | P6   |  100 | |
|      |       |         |        | +------+------+ |
| S4   | Clark |      20 | London | +------+------+ |
|      |       |         |        | | :pid | :qty | |
|      |       |         |        | +------+------+ |
|      |       |         |        | | P2   |  200 | |
|      |       |         |        | | P4   |  300 | |
|      |       |         |        | | P5   |  400 | |
|      |       |         |        | +------+------+ |
+------+-------+---------+--------+-----------------+
```

In a database context, a *view* is a fancy name to say "introducing a short name for a long expression". In SQL parlance:

```sql
CREATE VIEW london_suppliers_with_their_shipments AS
SELECT [...a long expression here...]
```

In Alf, which is a Ruby DSL, this "naming" process is as simple as:

```try
def london_suppliers_with_their_shipments
  group(
    join(
      restrict(suppliers, city: "London"),
      shipments),
    [:pid, :qty], :shipped)  
end

# Views simply introduce new names for relations.
# We can then "manipulate" them as usual:
restrict(london_suppliers_with_their_shipments, sid: "S1")
```

So far, so good. Here is where I start complaining about SQL once again, I'm affraid.

## Towards context-awareness: parameterized views

*Context-aware*, at first glance, is a fancy name to say "hey, there might be some query parameters involved". In the running example, maybe the "London" constant must change according to some business rules. More generally, most of the time queries are send to DBMSs in a particular context, e.g.

* On behalf of a specific user,
* Expecting results in a particular language (for internationalized data),
* From a particular area in the world,
* Targetting a specific audience,
* and so on.

Such context frequenly leads to query parameters and developers then make use of prepared statements:

```sql
SELECT * FROM suppliers WHERE city = ?
```

Or they rely on ORMs and query builders:

```ruby
whichCity = "London"
Supplier.where(city: whichCity)
```

As a query language, SQL does not natively support those `?` placeholders. This is a trick of call-level APIs that, among others, helps preventing SQL injection. There are no native way of building parameterized views in pure SQL. [As I said earlier](/blog/2014-12-03-what-would-a-functional-sql-look-like), SQL lacks support for *structuring* code, despite its name (I admit cheating here, *structured* here goes down to Dijkstra's structured programming and actually means *reasoning about*; SQL is rather friendly in this area, except maybe for the NULL mess).

In Alf, parameterized views are as simple as this:

```try
def suppliers_with_their_shipments(whichCity)
  group(
    join(
      restrict(suppliers, city: whichCity),
      shipments),
    [:pid, :qty], :shipped)  
end

# Change London by Paris here and see what happens
suppliers_with_their_shipments("London")
```

Trivial? Read on.

## Towards context-awareness: on the importance of names

Before moving to database viewpoints, let me make a short aside (the real reason of this aside will be clearer a bit later). What I write on this blog is from the pespective of somewhat complex software systems, that maybe *start* small, but evolve to meet complex data requirements. I'll write a post later that explains what *complex data requirements* is supposed to mean. In the mean time, think about multilingual data, complex visibility/security rules, multiple business viewpoints on the same database, cross-databases querying, etc. In all such cases we need approaches that help incorporating complexity slowly in the overal software mixture while keeping things simple along the way.

You probably know that "naming is the hardest problem in computer science". It is even harder if you are prevented from denoting different things by the *same* name, relying on the context for disambiguation. Imagine a natural language where a word would have only one very precise meaning and no overloading. Imagine a programming language where all variables would be global. Well,

* SQL has no real namespace support: all tables and all views must have different names. Hence abominations like `london_suppliers_with_their_shipments` above. Maybe the context provides disambiguation support? How about simply calling that view `suppliers` in that context?

* You probably know that [I'm not a big fan of object models and ORMs](http://www.revision-zero.org/orm-haters-do-get-it). Think about the `Supplier`, `Part` and `Shipment` classes. When using such a global object model the inability for the software to grow seems built in to me: you're entangled in a very strict and skimpy namespace with respect to data. You wouldn't want language designers to do such poor choices. Why the hell are you doing it to yourself?

How about?

```
parts (english)       parts (french)        parts (shipped by S1)
+------+-------+      +------+--------+     +------+-------+
| :pid | :name |      | :pid | :name  |     | :pid | :name |
+------+-------+      +------+--------+     +------+-------+
| P1   | Nut   |      | P1   | Ecrou  |     | P1   | Nut   |
| P2   | Bolt  |      | P2   | Boulon |     | P2   | Bolt  |
| P3   | Screw |      | P3   | Vis    |     +------+-------+
| P4   | Screw |      | P3   | Vis    |
| P5   | Cam   |      | P5   | Came   |
| P6   | Cog   |      | P6   | Rouage |
+------+-------+      +------+--------+
```

Please don't think "But! these are different *views*". I could write so many of such views that you'll quickly lack distinct words to distinguish them. These are "*the parts*", and the context of use of those two simple words must make clear what that means. One global context is simply not enough.

## Context-awareness

To sum up, a context-aware database interface/query language would allow denoting by `suppliers` in a context `C1` the same as what is denoted by `suppliers_with_their_shipments("London")` in another context `C2`. In other words, context-awareness would be enabled by a database query interface/language that

* Supports namespacing,
* Supports parameterized queries,
* Supports parameter values to be implicitely obtained from the context

Demonstrating the feature on try-alf is a bit tricky: Alf relies on Ruby modules for creating contextes cleanly and modules are not allowed here for security reasons. In essence, however, the feature works as follows:

```try
# This is the contextual city value
# - change it to Paris and see what happens
def whichCity
  "London"
end

# Definition of suppliers in C1, relying on suppliers from C2
def suppliers
  # `super` below captures suppliers in context C2, this is a hack
  # on how try-alf is implemented but that demonstrates the feature.
  c2_suppliers = super

  # our usual query, using whichCity which is in the same lexical scope
  group(
    join(
      restrict(c2_suppliers, city: whichCity),
      shipments),
    [:pid, :qty], :shipped)  
end

# Suppliers in context C1 denotes London suppliers with their shipments,
# while reusing the `suppliers` name and without being explicitely
# parameterized
suppliers
```

Conceptually, the example above illustrates the three important parts in the picture: the context *instantiation* that binds parameter names to values (`whichCity` is `"London"`), the context *definition* (`def suppliers`) that depends on parameters and relies on another context, and the context *usage*, here querying suppliers (`suppliers` on last line).

The key observation is that the last line abstracts from both the suppliers definition and the city value being London. In that context, `suppliers` denotes the suppliers in London together with their shipments. You can further query `suppliers` in that context. For instance, try changing the last line by:

```ruby
# Observe how `suppliers` here may denote whatever the context dictates
restrict(suppliers, sid: "S1")
```

## Database viewpoints

Viewpoints are simply the same idea, but applied to entire database schemas, loosely speaking. In other words, a viewpoint is simply a set of related, possibly context-aware, views. A simple example illustrates this. Suppose we want to see our database from the point of view of a particular city, say London:

* Only suppliers located in London
* Only parts located in London
* Only shipments of suppliers and parts we care about
* Abstracting from the city, as we know it's London (or Paris, or whatever)

This gives us a "sub database" if you want, that me might very well be queries as if it was the entire database. This is definitely what abstraction, and so-called [logical data independance](http://www.revision-zero.org/logical-data-independence), is about:

```try
# Change me by Paris and see what happens
def whichCity
  "London"
end

def suppliers
  allbut(restrict(super, city: whichCity), [:city])
end

def parts
  allbut(restrict(super, city: whichCity), [:city])
end

def shipments
  matching(matching(super, suppliers), parts)
end

# Query from that database viewpoint, let see the "entire" database
# for instance:
extend(DEE,
  suppliers: ->(t){ suppliers },
  parts:     ->(t){ parts },
  shipments: ->(t){ shipments })
```

So, the Suppliers and Parts exemplar from a London point of view:

```
+----------------------------+-------------------------------------+------------------------+
| :suppliers                 | :parts                              | :shipments             |
+----------------------------+-------------------------------------+------------------------+
| +------+-------+---------+ | +------+-------+--------+---------+ | +------+------+------+ |
| | :sid | :name | :status | | | :pid | :name | :color | :weight | | | :sid | :pid | :qty | |
| +------+-------+---------+ | +------+-------+--------+---------+ | +------+------+------+ |
| | S1   | Smith |      20 | | | P1   | Nut   | Red    |  12.000 | | | S1   | P1   |  300 | |
| | S4   | Clark |      20 | | | P4   | Screw | Red    |  14.000 | | | S1   | P4   |  200 | |
| +------+-------+---------+ | | P6   | Cog   | Red    |  19.000 | | | S1   | P6   |  100 | |
|                            | +------+-------+--------+---------+ | | S4   | P4   |  300 | |
|                            |                                     | +------+------+------+ |
+----------------------------+-------------------------------------+------------------------+
```

The "same" database, from a Paris point of view:

```
+----------------------------+-------------------------------------+------------------------+
| :suppliers                 | :parts                              | :shipments             |
+----------------------------+-------------------------------------+------------------------+
| +------+-------+---------+ | +------+-------+--------+---------+ | +------+------+------+ |
| | :sid | :name | :status | | | :pid | :name | :color | :weight | | | :sid | :pid | :qty | |
| +------+-------+---------+ | +------+-------+--------+---------+ | +------+------+------+ |
| | S2   | Jones |      10 | | | P2   | Bolt  | Green  |  17.000 | | | S2   | P2   |  400 | |
| | S3   | Blake |      30 | | | P5   | Cam   | Blue   |  12.000 | | | S3   | P2   |  200 | |
| +------+-------+---------+ | +------+-------+--------+---------+ | +------+------+------+ |
+----------------------------+-------------------------------------+------------------------+
```

## Viewpoint composition: Embracing database values!

Since version 0.15.0, Alf supports those viewpoints, and composition of them, through Ruby modules and the `super` keyword. Ruby simply does the rest (lexical scoping, composition, etc.). Maybe that's a bit too magical to your taste, or it prevents from truly understanding what's going on here. So let me explain it a bit differently now, by making the magic explicit.

If you abstract from updates, a database can simply be seen as a huge value. Not any kind of value. As far as the relational model is concerned, it is a collection of *relation* values specifically, like our *suppliers*, *parts* and *shipments* relation values above. This "collection" can be made very precise by stating that a database is itself a tuple value, with every attribute being a relation value. Let call it `base`, in reference to so-called 'base' tables (relation variables in our parlance here):

```ruby
def base
  {
    suppliers: Relation(...),
    parts:     Relation(...),
    shipments: Relation(...)
  }
end
```

With a database conceptually modeled as a tuple value, one simply has to accept that when a query like the following one is sent to the database:

```try
# Get suppliers located in London
restrict(suppliers, city: "London")
```

Then, under the hood, the database management system has to resolve `suppliers` to actually denote `base.suppliers`, where `.` would be a tuple attribute dereferencing operator:

```ruby
# Get suppliers located in London (from the current database value)
restrict(base.suppliers, city: "London")
```

In other words, a similar mechanism to the one used previously, makes implicit what the context makes obvious (that users want to query the *last known* database value; yet is it that obvious after all?). That is, using the usual Ruby syntax of this blog post once again:

```ruby
def base
  get_last_known_database_value
end

def suppliers
  base.suppliers
end

restrict(suppliers, city: "London")
```

Now, if one designs a language with database values as first-class citizen, then all this context-aware viewpoint stuff becomes fairly trivial: viewpoints are database values obtained from other database values, that's all. More precisely, it naturally leads seeing viewpoints as *functions* from database values to database values. Let's take our London/Paris viewpoint above as an example:

```ruby
def fromCity(db, whichCity)
  {
    suppliers: allbut(restrict(db.suppliers, city: whichCity), [:city]),
    parts:     allbut(restrict(db.parts, city: whichCity), [:city]),
    shipments: ...
  }
end

# Viewpoint instantiation from the `base` database
londonViewpoint = cityViewpoint(base, "London")

# Query as ususal
restrict(londonViewpoint.suppliers, sid: "S1")
```

Viewpoint composition boils down to functional composition and is trivial too. Suppose we have an multilingual version of the suppliers and parts database, and another viewpoint that "projects" it on a particular language. Then,

```
# Project `db` on language `lang`
def inLanguage(db, lang)
  {
    suppliers: ...,
    parts:     ...
    shipments: ...
  }
end

# Viewpoint instantiations and composition
db = inLanguage(fromCity(base, "London"), "fr")

# Query as ususal
restrict(db.suppliers, sid: "S1")
```

And that's all for today. It's interresting to classify database viewpoint according to whether those functions are type preserving or not (that is, whether they preserve the database 'schema' itself), but that will be the topic of another post.

(If you liked this post, you should probably [follow me on twitter](http://twitter.com/blambeau), star [try-alf on github](http://github.com/alf-tool/try-alf), [send me an encouragement email](mailto:blambeau@gmail.com) or hire me on your next data problem!)
