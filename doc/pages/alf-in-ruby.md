# Alf in Ruby

This page provides an introduction to using Alf in Ruby programs. Please refer
to the available examples, blog posts, and API documentation for further
details and advanced use cases. The following sections cover:

* Querying various data sources using `Alf.query`
* Understanding query results and hacking with `Relation`
* Towards lazy evaluation and database updates with `Relvar`
* More on obtaining data source connections

## Connect and query

The easiest way to connect and query a data source using Alf is through
`Alf.query`. For instance, suppose that you have the <a target="_blank"
href="/downloads/sap.sqlite3">sap.sqlite3</a> database file available in the
current folder. Then:

```
require 'alf'
require 'sqlite3'

rel = Alf.query("sap.sqlite3") do
  restrict(suppliers, city: 'London')
end
puts rel
```

Your query (inside the block) can be as complex as you like. As of relational
algebra's closure property, you can chain relational operators without any
restriction.

`Alf.query`'s first argument can also be:

* A [Path](https://github.com/eregon/path) or
  [Pathname](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/pathname/rdoc/Pathname.html),
  or string path to a sqlite file with a `.db`, `.sqlite` or `.sqlite3` extension,
  as in the example above.
* A [Path](https://github.com/eregon/path) or
  [Pathname](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/pathname/rdoc/Pathname.html)
  instance to a folder containing recognized files

        # Let query .csv/.json/.yaml files in the current folder
        Alf.query(Path.pwd) do
          ...
        end

* A database URL recognized by
  [Sequel](http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html):

        Alf.query('postgres://user:password@host/dbname') do
          ...
        end
  
* A [Sequel](http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html)
  `Database` instance.

        db = ::Sequel.connect('postgres://user:password@host/dbname')
        Alf.query(db) do
          ...
        end

## Relation

`Alf.query` always returns the query result as a `Alf::Relation` instance. The
latter is an in-memory relation, that is, a set of tuples entirely independent
from the concrete datasource it comes from.

This `Relation` has a bunch of useful methods, as demonstrated by the
following example:

```
require 'alf'
require 'sqlite3'

rel = Alf.query("sap.sqlite3") do
  restrict(suppliers, city: 'London')
end

# info and metadata
rel.size       # number of tuples
rel.empty?     # is it an empty set of tuples?
rel.attr_list  # the list of attribute names as an Alf::AttrList
rel.heading    # information about types as a Alf::Heading

# export methods
rel.to_a       # an array of ruby hashes
rel.to_text    # the ascii table result
rel.to_json    # all tuples, but in json
rel.to_csv     # all tuples, but in csv
rel.to_yaml    # all tuples, but in yaml

# the entire algebra, in postfix, OO syntax
rel.project([:sid])
rel.rename(...)
rel.join(...)

# tuple iteration
rel.each do |supplier|
  puts supplier.name
end

# tuple extraction (raises unless exactly one tuple)
rel.tuple_extract
```

`Alf::Relation` implements a pure immutable value, with Alf's relational
algebra shipped in an object-oriented style. It consistently implements
`hash`, `==` and `eql?`, you can thus use it in hashes, compare relations for
equality, and so on. No surprise. BUT. The object-oriented relational algebra
implemented by `Relation` comes at a price: immediate evaluation, no
optimization, in-memory implementation. Called on a `Relation`, a relational
operator returns a `Relation`.

For this reason, working with the `Relation` class is not always a good
choice. For example, it is not recommended when you want to incrementally
build complex queries against a data source, if you need to avoid loading all
tuples in memory, or if you want to use logical query optimization.

## Relvar

`Relvar` stands for `relation variable`. Conceptually, a relvar is a variable
whose value is a relation. Thus, it has a location and it can be updated. In
addition, we distinguish between two kinds of relvars: _base_ relvars (aka
tables) and _virtual_ also called _derived_ variables (aka views).

Alf uses the concept of relvar as a localized, virtual, set of tuples attached
to the concrete datasource(s) it comes from. Unlike `Relation`, `Relvar` does
not keep the tuples in memory and always recomputes them if needed. It does
**not** implement `hash`, `==` and `eql?` with respect to the set of tuples it
virtually denotes.

`Relvar` instances are attached to particular data sources and can only be
obtained and used in the context of at least one database connection (see next
section). Once obtained, a relvar has an object-oriented API very similar to
the one of `Relation`. A few differences and additional methods though:

```
require 'alf'
require 'sqlite3'

# See next section about this
Alf.connect("sap.sqlite3") do |conn|

  # Remember that you can no longer use the relvar when the connection
  # has been closed!
  relv = conn.relvar do
    restrict(suppliers, city: 'London')
  end

  # Returns the set of tuples as a Relation
  relv.value

  # the entire algebra, in postfix, OO syntax
  relv.project([:sid])  # returns another relvar, no actual computation
  rel.rename(...)
  rel.join(...)

  # update (VERY experimental, use with care, especially on virtual relvars)
  relv.delete(predicate)
  relv.insert(tuples)
  relv.upsert(tuples)
  relv.update(updating, predicate)
  relv.affect(relation)

  # locking (even more experimental)
  relv.lock{
    # executes the block with a lock on all underlying base relvars
  }

end
```

## Lower-level connection API

When building more complex software, the use of `Alf`'s facade API is somewhat
too limited. The following example shows more about hacking with lower-level
`Alf::Database` and `Alf::Database::Connection` objects:

```
require 'alf'
require 'sqlite3'

# Declare configuration once for all (as well as some options not
# covered here).
DB = Alf::Database.new("sap.sqlite3")

# Connect for querying and obtaining relvars. The connection will be
# automatically closed when the block execution ends. The `conn` object is
# NOT thread-safe. 
DB.connect do |conn|
  rel = conn.query do
    restrict(suppliers, city: 'London')
  end
  puts rel
end

# Yet another way of obtaining a connection. You MUST ensure that
# you properly disconnect.
begin
  conn = DB.connection
  conn.query do
    restrict(suppliers, city: 'London')
  end
  puts rel
ensure
  conn.close if conn
end
```
