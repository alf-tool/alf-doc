# alf-explain

Show the logical (optimizer) and physical (compiler) plans of a query.

## Synopsis

`alf` explain *QUERY*

## Description

This command prints the logical and physical query plans for QUERY to
standard output:

* The logical plan is post-optimizer and allows checking that the latter
  performs correctly.
* The physical plan provides information about compilation. In particular it
  provides feedback about the effective delegation to underlying database
  engines, as well as involved SQL queries.

## Example

`alf` `--examples` explain "restrict(suppliers, city: 'London')"
