# alf

Relational algebra at your fingertips

## Synopsis

`alf` [`--version`] [`--help`]

`alf` *FILE.alf*

`alf` show *QUERY*

`alf` explain *QUERY*

`alf` help *OPERATOR*

## Options

  `--rash`
    Render output as ruby hashes

  `--text`
    Render output as a text table

  `--yaml`
    Render output in YAML

  `--json`
    Render output in JSON

  `--csv`
    Render output in CSV

  `--examples`
    Use the suppliers and parts example database

  `--db=DB`
    Set the database (adapter) to use. Recognized values can be
    folders with recognized files, or an URL to a SQL database
    (e.g. postgres://user:pass@host/database)

  `--stdin=READER`
    Specify the kind of reader when reading on standard input
    (i.e. rash, csv, json, ruby, or yaml)

  `-Idirectory`
    Specify $LOAD_PATH directory (may be used more than once)

  `-rlibrary`
    Require the specified ruby library, before executing alf

  `--ff=FORMAT`
    Specify the floating point format

  `--[no-]pretty`
    Enable/disable pretty print best effort

  `-h`, `--help`
    Show this help

  `-v`, `--version`
    Show version and copyright

## Commands

  `help`
    Shows help about a specific command, relational operator, aggregator,
    or predicate.

  `show`
    Evaluates a query and shows the result in a specified format.

  `metadata`
    Show metadata for a query (heading, keys).

  `explain`
    Show the logical (optimizer) and physical (compiler) plans of a query.

  `repl`
    Launches Alf's Read-Eval-Print-Loop (REPL) web application.

See `alf help COMMAND` for details about a specific command or `alf help
OPERATOR` for documentation of a relational operator.
