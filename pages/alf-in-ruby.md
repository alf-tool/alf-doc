# Alf in Ruby

This page describes basic information for using Alf in Ruby programs. Please
refer to the available examples, blog posts, and API documentation for further
details.

## Connect and query

The most immediate way to connect and query a data source using Alf is through
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

`Alf.query`'s first argument can actually be:

* A [Path](https://github.com/eregon/path) or
  [Pathname](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/pathname/rdoc/Pathname.html),
  or string path to a sqlite file with a `.db`, `.sqlite` or `.sqlite3` extension,
  as in the example above.
* A [Path](https://github.com/eregon/path) or
  [Pathname](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/pathname/rdoc/Pathname.html)
  instance to a folder

        # Let query .csv/.json files in the current folder
        Alf.query(Path.pwd) do
          ...
        end

* A database URL recognized by
  [Sequel](http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html):

        Alf.query('postgres://user:password@host/dbname') do
          ...
        end
  
* A [Sequel](http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html)
  `Database` instance (to use connection pooling)

        db = ::Sequel.connect('postgres://user:password@host/dbname')
        Alf.query(db) do
          ...
        end

## Relation

`Alf.query` always returns the query result as a `Alf::Relation` instance. The
latter is an in-memory relation, that is, a set of tuples entirely detached
from the concrete datasource it actually comes from.

This `Relation` has a bunch of useful methods, as demonstrated by the
following example:

```
require 'alf'
require 'sqlite3'

rel = Alf.query("sap.sqlite3") do
  restrict(suppliers, city: 'London')
end

# info and metadata
rel.size     # number of tuples
rel.empty?   # is it an empty set of tuples?
rel.attr_list  # the list of attribute names as an Alf::AttrList
rel.heading    # information about types as a Alf::Heading

# export methods
rel.to_a     # an array of ruby hashes
rel.to_text  # the ascii table result
rel.to_json  # all tuples, but in json
rel.to_csv   # all tuples, but in csv
rel.to_yaml  # all tuples, but in yaml

# algebra methods
rel.project([:sid]) # the entire algebra, in postfix, OO syntax
rel.rename(...)
rel.join(...)

# iteration
rel.each do |supplier|
  puts supplier.name
end
```

`Alf::Relation` implements a pure immutable value, with Alf's relational
algebra shipped with an object-oriented style. It consistently implements
`hash`, `==` and `eql?`, you can use it as a Hash key, compare relations for
equality, and so on. No surprise. BUT. The object-oriented relational algebra
implemented by `Relation` comes at a price: immediate evaluation, no
optimization, in-memory implementation. Called on a `Relation`, a relational
operator returns a `Relation`.

For this reason, working with the `Relation` class is not always a good
choice. This is for example the case when you want to incrementally build
complex queries against a data source, avoid loading all tuples in memory, or
profit from the query optimizer.

## Relvar

`Relvar` stands for `relation variable`. Conceptually, a relvar is a variable
whose value is a relation. Thus, it has a location (where is the value
located?) and it can be updated. In addition, we distinguish between two kinds
of relvars: _base_ relvars (aka tables) and _virtual_ variables (aka views).

Alf uses the concept of relvar as a localized, virtual, set of tuples attached
to the concrete datasource(s) it comes from. Unlike `Relation`, `Relvar` does
not keep the tuples in memory and always recomputes them if needed. It does
**not** implement `hash`, `==` and `eql?` with respect to the set of tuples it
virtually denotes, but according to the relational expression it captures and
the datasources it is attached to.

`Relvar` instances are obtained through `Alf.relvar` and have an object-oriented
API very similar to the one of `Relation`. A few differences and additional
methods though:

```
require 'alf'
require 'sqlite3'

relv = Alf.relvar("sap.sqlite3") do
  restrict(suppliers, city: 'London')
end

# Returns the set of tuples as a Relation
relv.value

# algebra
relv.project([:sid])  # returns another relvar, no actual computation

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
```

## Lower-level connection API

When building more complex software, `Alf`'s facade API is simply not enough.
The following example shows how to hack with lower-level `Alf::Database` and 
`Alf::Database::Connection` objects:

```
require 'alf'
require 'sqlite3'

# Declare configuration once for all (as well as some options not
# covered here).
DB = Alf::Database.new("sap.sqlite3")

# Connect where you want!, the `conn` object is NOT thread-safe
# Connection is automatically closed when the block is exited.
DB.connect do |conn|
  rel = conn.query do
    restrict(suppliers, city: 'London')
  end
  puts rel
end

# Yet another way of obtaining a connection. You MUST ensure that
# you properly disconnect
begin
  conn = DB.connection
  conn.query do
    restrict(suppliers, city: 'London')
  end
ensure
  conn.close if conn
end
```
