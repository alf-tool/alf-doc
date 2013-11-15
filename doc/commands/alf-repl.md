# alf-repl

Launches Alf's Read-Eval-Print-Loop (REPL) web application.

## Synopsis

`alf` [`--db=...`] repl

## Description

This command launches the REPL in the current data context defined by the
`.alfrc` file and common alf options (e.g. `--db`).

## Example

`alf` `--db=postgres://...` repl
