# alf-show

Evaluates a query and shows the result.

## Synopsis

`alf` [`--csv`|`--json`...] show *QUERY* -- [*ORDERING*]

## Description

Take a query argument and execute it against the current database (according
to options passed to the `alf` main command). Show the result on standard
output. The format (e.g. json) may be specified through `alf` main options.

When an ordering is specified, tuples are rendered in the order specified.

## Example

`alf` `--examples` show "restrict(suppliers, city: 'London')" -- name DESC
