# How to learn Alf?

This documentation comes with a log of examples that you can try online. This
is probably one of the most efficient ways to learn. More specifically, here
is a possible roadmap:

* Start with the documentation of a relational operator,
* Try the examples, play with them,
* Read the description and implementation notes,
* Try to understand the definitions when an operator can be defined in terms
  of other operators. Those definitions use the closure property of relational
  algebra a lot. From there, jump to another operator.
* If needed, have a loot at predicates and other concepts to better understand
  the language and operator signatures.

The query language aims at being as intuitive as possible, even if some
background is definitely needed. Two main directions here:

* Make sure to eventually read the [relational
  basics](/doc/relational-basics).
* If you do not know ruby, make sure to eventually read the [ruby
  basics](/doc/ruby-basics).

# How to get started outside of try-alf.org ?

Alf comes as a ruby gem. You need ruby >= 1.9.3.

```
gem install alf [sqlite3] [pg]
```

Once installed, the command line tool is available:

```
alf --help
alf --examples show suppliers
alf --db="postgres://user:password@host/database" show tablename
```

Have a look at the [Alf in Ruby](/doc/alf-in-ruby) and [Alf in
Shell](/doc/alf-in-shell) pages for getting started depending on the kind of
context in which you plan to use it.
