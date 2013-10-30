# Alf in Shell

This page provides an introduction to using Alf in Shell. Please refer to `alf
--help` and `alf help COMMAND` for further details. Note that, Alf does not
currently provide ways to perform updates using the shell interface. The
following section describe the most typical use cases of the commandline tool:

* Querying data from files (.json, .csv and the like)
* Querying SQL databases around
* Exporting data in various format
* Piping with alf itself... and other processes
* Keeping configuration in a .alfrc file
* Executing and analyzing complex queries

## Querying data files

Alf recognizes various data formats such as `.csv`, `.json`, `.yaml` and so
on. It allows you to query such files and export data in those formats.

Suppose that you have the <a target="_blank"
href="/downloads/suppliers.csv">suppliers.csv</a> file in the current folder.
Visualizing the content of this file as a relation is as simple as:

```sh
$ alf show suppliers
```

Please note that the `.csv` extension must not be specified. In fact, Alf
connects to the current folder as if it was a database, so that recognized
files are seen as candidate relations. In other words, the example below
works as soon as `suppliers` and `supplies` can be tracked to recognized files.
Try it yourself using <a target="_blank" href="/downloads/suppliers.csv">suppliers.csv</a>
and <a target="_blank" href="/downloads/supplies.json">supplies.json</a>:

```sh
$ alf show "join(suppliers, supplies)"
```

## Querying databases

Querying databases is not different. The `--db` option allows you to specify
which database to connect to. For instance, the invocations above are
shortcuts for:

```sh
$ alf --db=. show suppliers
```

Therefore, querying a SQLite database <a target="_blank"
href="/downloads/sap.sqlite3">sap.sqlite3</a> in the current folder:

```sh
alf --db=sap.sqlite3 show "restrict(suppliers, city: 'London')"
```

And a postgresql database:

```sh
alf --db=postgres://user:password@host/database show parts
```

Alf example database (the suppliers and parts examplar) can also be used when
learning alf:

```
alf --examples show suppliers
```

## Exporting data in various formats

By default, `alf show` outputs relations as a plain/text ascii table. You can
of course specify other data output formats. For instance, exporting a query
in .json can be done as follows:

```sh
alf --json show "restrict(suppliers, city: 'London')"
```

Other data formats are available through `--csv` and `--yaml` and `--rash`
(ruby hashes, one per line).

## Piping and data conversion

Alf also supports receiving data from its standard input. Suppose for example
that you want to restrict some json tuples outputted by some process, here a
simple `cat`:

```
cat suppliers.json | alf --stdin=json show "restrict(stdin, city: 'London')"
```

That means that you can very easily use alf to convert from one data format
to another one. Converting a .csv file to .json?

```
cat suppliers.csv | alf --stdin=csv --json show 
```

## Using an .alfrc file

When invoked from the command line, Alf looks after a `.alfrc` in the current
folder and its ancestors and loads its default configuration from there if
found. A typical `.alfrc` file looks as follows:

```
alfrc do |c|
  # Adapter to use, same as `--db=...`
  c.adapter = "postgres://user:password@host/database"

  # additional load paths, same as `-Ilib -Ispec`
  c.load_paths |= [ "lib", "spec" ]

  # additional libraries to require, same as `-rfoo -rbar`
  c.requires |= ["foo", "bar"]
end
```

See `Alf::Shell::Alfrc` for more information and available options.

## Evaluating and analyzing complex queries

Passing queries between quotes may become cumbersome when they get complex.
Hopefully, `Alf` recognizes files with an `.alf` extension and treat them
in a special way. Suppose you have a complex query in a `complex-query.alf`
file.

```
suppliers_by_city = group(suppliers, [:sid, :name, :status], :suppliers)
parts_by_city     = group(parts, [:city], :parts, allbut: true)
joined            = join(suppliers_by_city, parts_by_city)
restrict(joined, city: "London")
```

Then, passing this file to `show` simply executes the complex query:

```sh
$ alf --db=... show complex-query.alf
```

In addition, you can always verify how Alf optimize and execute your queries
using the `explain` command:

```sh
$ alf --db=... explain complex-query.alf
```
