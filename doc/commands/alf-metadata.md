# alf-metadata

Show metadata about a query, such as heading and candidate keys.

## Synopsis

`alf` metadata *QUERY*

## Description

This command prints some metadata (e.g. heading, keys, etc.) about the
expression passed as first argument.

## Example

`alf` `--examples` metadata "restrict(suppliers, city: 'London')"
