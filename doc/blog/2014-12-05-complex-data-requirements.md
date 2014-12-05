# SQL, Query builders and ORMs are not up to the task

My last post ["What would a functional SQL look like"](/blog/http://www.try-alf.org/blog/2014-12-03-what-would-a-functional-sql-look-like) generated a few comments that made me want clarifying a few things. In short,

> No, you can't really do in SQL what Alf allows doing. Neither can you do it with ORMs and query builders.

But,

> You could do it with a language with first-class relations; Alf provides an example.

But what kind of task are we talking about? Well, implementing *complex* data requirements. That's vague, I know, so I decided to grow an example.

## Step 1: Serving data on the web

As a developer, you end up with that task "à la mode" of having to serve information about the [suppliers](/?src=c3VwcGxpZXJz), [parts](/?src=cGFydHM=) and [shipments](/?src=c2hpcG1lbnRz) from your database to the world wide web. The database is a *relational* database and you have a normalized schema (for very good reasons).

For the record, here is the data we are talking about (each is a SQL 'table', if you want).

```
suppliers                             parts                                          shipments
+------+-------+---------+--------+   +------+-------+--------+---------+--------+   +------+------+------+
| :sid | :name | :status | :city  |   | :pid | :name | :color | :weight | :city  |   | :sid | :pid | :qty |
+------+-------+---------+--------+   +------+-------+--------+---------+--------+   +------+------+------+
| S1   | Smith |      20 | London |   | P1   | Nut   | Red    |  12.000 | London |   | S1   | P1   |  300 |
| S2   | Jones |      10 | Paris  |   | P2   | Bolt  | Green  |  17.000 | Paris  |   | S1   | P2   |  200 |
| S3   | Blake |      30 | Paris  |   | P3   | Screw | Blue   |  17.000 | Oslo   |   | S1   | P3   |  400 |
| S4   | Clark |      20 | London |   | P4   | Screw | Red    |  14.000 | London |   | S1   | P4   |  200 |
| S5   | Adams |      30 | Athens |   | P5   | Cam   | Blue   |  12.000 | Paris  |   | S1   | P5   |  100 |
+------+-------+---------+--------+   | P6   | Cog   | Red    |  19.000 | London |   | S1   | P6   |  100 |
                                      +------+-------+--------+---------+--------+   | S2   | P1   |  300 |
                                                                                     | S2   | P2   |  400 |
                                                                                     | S3   | P2   |  200 |
                                                                                     | S4   | P2   |  200 |
                                                                                     | S4   | P4   |  300 |
                                                                                     | S4   | P5   |  400 |
                                                                                     +------+------+------+
```

In a [RESTful](http://en.wikipedia.org/wiki/Representational_state_transfer) spirit, you map the resources as follows:

* The `suppliers` resource collection served on `http://my-sap.com/suppliers/`
* The `supplier` resource on `http://my-sap.com/suppliers/{sid}`
* and so on.

(This one-to-one mapping between RESTful resources and database tables is not really RESTful-minded, I'll make the example more convincing in a second. If you don't know what RESTful is, simply ignore that detail, it's not important to understand the message here).

For the suppliers collection you write some code (possibly using your prefered query builder or ORM) that, in essence, evaluates:

```sql
SELECT sid, name, status, city FROM suppliers
```

and serves it, negociated as `application/json` or `text/csv` data, as:

```
+------+-------+---------+--------+
| :sid | :name | :status | :city  |
+------+-------+---------+--------+
| S1   | Smith |      20 | London |
| S2   | Jones |      10 | Paris  |
| S3   | Blake |      30 | Paris  |
| S4   | Clark |      20 | London |
| S5   | Adams |      30 | Athens |
+------+-------+---------+--------+
```

So far so good, direct SQL allows doing it, ORMs and query builders allow doing it, Alf allows doing it, no hard programming is required but for fools (for the "querying database" part of the task, of course). Great.

## Step 2: A Domain Driven Design aggregate

A 'flat', normalized, database schema is great. It does not mean that information consumers have to see data through that lesnse only. In other words, it might make sense to expose views, or reports, or domain aggregates ... call them however you want.

How about?

> Suppliers together with their respective shipments, including the part name, color and weight... semi-structured please!

```
+------+-------+---------+--------+---------------------------------------------+
| :sid | :name | :status | :city  | :supplies                                   |
+------+-------+---------+--------+---------------------------------------------+
| S1   | Smith |      20 | London | +------+------+--------+--------+---------+ |
|      |       |         |        | | :pid | :qty | :pname | :color | :weight | |
|      |       |         |        | +------+------+--------+--------+---------+ |
|      |       |         |        | | P1   |  300 | Nut    | Red    |  12.000 | |
|      |       |         |        | | P2   |  200 | Bolt   | Green  |  17.000 | |
|      |       |         |        | | P3   |  400 | Screw  | Blue   |  17.000 | |
|      |       |         |        | | P4   |  200 | Screw  | Red    |  14.000 | |
|      |       |         |        | | P5   |  100 | Cam    | Blue   |  12.000 | |
|      |       |         |        | | P6   |  100 | Cog    | Red    |  19.000 | |
|      |       |         |        | +------+------+--------+--------+---------+ |
| S2   | Jones |      10 | Paris  | +------+------+--------+--------+---------+ |
|      |       |         |        | | :pid | :qty | :pname | :color | :weight | |
|      |       |         |        | +------+------+--------+--------+---------+ |
|      |       |         |        | | P1   |  300 | Nut    | Red    |  12.000 | |
|      |       |         |        | | P2   |  400 | Bolt   | Green  |  17.000 | |
|      |       |         |        | +------+------+--------+--------+---------+ |
...
| S5   | Adams |      30 | Athens | +------+------+--------+--------+---------+ |
|      |       |         |        | | :pid | :qty | :pname | :color | :weight | |
|      |       |         |        | +------+------+--------+--------+---------+ |
|      |       |         |        | +------+------+--------+--------+---------+ |
+------+-------+---------+--------+---------------------------------------------+
```

We already lost a pure SQL approach as a candidate. Except maybe with extensions like JSON support in PostgreSQL, you won't be able to construct such a relation value in standard SQL (and the JSON approach hardly scales to more complex requirements). You can of course obtain a 'flat' (yet information equivalent) version of it, but the heavy lifting of regrouping shipments per suppliers is then up to the developer:

```sql
SELECT S.sid, S.name, S.status, S.city, SP.pid, SP.qty, P.name as pname, P.color, P.weight
FROM suppliers S
LEFT JOIN shipments SP on SP.sid=S.sid
LEFT JOIN parts P on SP.pid=P.pid
```

You'll make sure to use those two `LEFT JOIN`, otherwise you forget S5 who has no shipments. The heavy lifting code will also take care of the NULL values you'll end up with:

```
 sid | name  | status |  city  | pid  | qty  | pname | color | weight
-----+-------+--------+--------+------+------+-------+-------+--------
 S1  | Smith |     20 | London | P1   | 300  | Nut   | Red   |     12
 S1  | Smith |     20 | London | P2   | 200  | Bolt  | Green |     17
 S1  | Smith |     20 | London | P3   | 400  | Screw | Blue  |     17
 S1  | Smith |     20 | London | P4   | 200  | Screw | Red   |     14
 S1  | Smith |     20 | London | P5   | 100  | Cam   | Blue  |     12
 S1  | Smith |     20 | London | P6   | 100  | Cog   | Red   |     19
 S2  | Jones |     10 | Paris  | P1   | 300  | Nut   | Red   |     12
 S2  | Jones |     10 | Paris  | P2   | 400  | Bolt  | Green |     17
...
 S5  | Adams |     30 | Athens | NULL | NULL | NULL  | NULL  |   NULL
```

Query builders won't help much here. They are heavily coupled to SQL and can't be more powerful than it. Those that are generally embed features that look like Object-Relation-Mapping (ORM).

ORMs do the heavy lifting for you, by exposing a data model that you can navigate. However, if you want them to avoid generating `N+1` queries to the underlying database, you'll have to guide them a little bit. You'll make sure to use those `LEFT` joins, otherwise you forget S5 who has no shipments.

How about doing it in Alf, with a query plan involving a constant number of queries?

```try
image(
  suppliers,
  join(
    shipments,
    rename(project(parts, [:pid, :name, :color, :weight]), :name => :pname)),
  :supplies)
```

Let me take this as an opportunity to challenge the [new syntax](/blog/http://www.try-alf.org/blog/2014-12-03-what-would-a-functional-sql-look-like) (a bit cryptic maybe?):

```ruby
suppliers
  | ( shipments
      | join parts
      | select @pid, @color, @weight, pname: @name
      | image :supplies )
```

## Step 3: How about the singular resource?

Remember the `supplier` resource mapped on `http://my-sap.com/suppliers/{sid}`? Now that we've built the collection, it should be a simple filter afterwards. From a software engineering point of view, it obvioulsy makes sense to do it in a composable way (we certainly want to reuse the code we've just built, don't we?).

No problem in SQL (but remember, we already lost that approach with the previous requirement).

```
SELECT * FROM (
  SELECT S.sid, S.name, S.status, S.city, SP.pid, SP.qty, P.name as pname, P.color, P.weight
  FROM suppliers S
  LEFT JOIN shipments SP on SP.sid=S.sid
  LEFT JOIN parts P on SP.pid=P.pid
) R
WHERE R.sid = ?
```

(The query can be simplified to avoid the subquery, but I want to show the composition explicitly, as a witness of code reuse).

Query builders + heavy lifting code will allow something similar. Some inversion of control is needed due to the heavy lifting. You can filter the result "manually" afterwards, but that's not very efficient, since we know it won't be done by the underlying DBMS but by the host language on the resulting array.

```
# Returns an Array of something              # Idem.
def collection                               def collection(filter = true)
  heavyLifting(                                heavyLifting(
    suppliers                                    suppliers
      .leftjoin(shipments)                         .leftjoin(shipments)
      .leftjoin(parts)                             .leftjoin(parts)
      .select(...)                                 .select(...)
  )                                                .where(filter)   # need this !!!!!!
end                                            )
                                             end

# DOES NOT WORK, no longer a query           # the filter must be injected instead
def singular(which_sid)                      def singular(which_sid)
  collection.where(sid: which_sid)             collection(sid: which_sid)
end                                          end

singular("S1")                               singular("S1")
```

ORMs take another approach. You navigate the data model. I don't know how to illustrate compositional code reuse, or if that makes sense to say so. If you want to avoid sending N+1 queries to the database anyway, you'll rely on the SQL query builder underlying your favorite ORM. You'll make sure to use those two `LEFT JOIN`, otherwise you forget S5 who has no shipments.

In Alf (and any language with first-class relations and lazy evaluation)? No problem. Yet the filtering is done by the underlying (SQL) DBMS, not by Alf itself:

```try
# No filter injection here. The code has NOT changed; the result is a Relation.
def collection
  image(
    suppliers,
    join(
      shipments,
      rename(project(parts, [:pid, :name, :color, :weight]), :name => :pname)),
    :supplies)
end

# Observe how this is different from filter (e.g. code) injection. It's just a
# parameterized query here, similar to the use of '?' in the SQL version.
def singular(which_sid)
  # Actual filtering will be done by the RDBMS
  restrict(collection, sid: which_sid)
end

singular("S1")
```

```
+------+-------+---------+--------+---------------------------------------------+
| :sid | :name | :status | :city  | :supplies                                   |
+------+-------+---------+--------+---------------------------------------------+
| S1   | Smith |      20 | London | +------+------+--------+--------+---------+ |
|      |       |         |        | | :pid | :qty | :pname | :color | :weight | |
|      |       |         |        | +------+------+--------+--------+---------+ |
|      |       |         |        | | P1   |  300 | Nut    | Red    |  12.000 | |
|      |       |         |        | | P2   |  200 | Bolt   | Green  |  17.000 | |
|      |       |         |        | | P3   |  400 | Screw  | Blue   |  17.000 | |
|      |       |         |        | | P4   |  200 | Screw  | Red    |  14.000 | |
|      |       |         |        | | P5   |  100 | Cam    | Blue   |  12.000 | |
|      |       |         |        | | P6   |  100 | Cog    | Red    |  19.000 | |
|      |       |         |        | +------+------+--------+--------+---------+ |
+------+-------+---------+--------+---------------------------------------------+
```

For the record, the same composition with the new syntax:

```ruby
suppliers
  | ( shipments
      | join parts
      | select @pid, @color, @weight, pname: @name
      | image :supplies )
  | restrict sid: "S1"
```

How does that work? How is the filtering done by the (SQL) RDBMS, if SQL has no support for the grouping implied by `image` in the first place and if `restrict` appears later in the pipeline? Thanks to Alf's query optimizer. The query above is equivalent to the following one and Alf does the rewrite for you:

```ruby
suppliers
  | restrict sid: "S1"
  | ( shipments
      | restrict sid: "S1"
      | join parts
      | select @pid, @color, @weight, pname: @name
      | image :supplies )
```

These are *simple* data requirements. Let make them complex now.

## Step 4: Internationalization and context awareness

The previous requirement has shown how a relation can be 'filtered' *after the fact*, without changing our original code and without (too much) performance penalty:

```ruby
restrict(collection, ...)
```

Let take a dual affair and "internationalize the parts" as a new requirement, without changing the original code of `collection` either. Suppose the database schema evolves to include part names and colors in different languages. Following normalization rules, `:name` and `:color` disappear from `parts`; a new table makes them dependent of a composite key `:pid, :lang`.

```
parts_i18n
+------+-------+--------+--------+
| :pid | :lang | :name  | :color |
+------+-------+--------+--------+
| P1   | en    | Nut    | Red    |
| P2   | en    | Bolt   | Green  |
| P3   | en    | Screw  | Blue   |
| P4   | en    | Screw  | Red    |
| P5   | en    | Cam    | Blue   |
| P6   | en    | Cog    | Red    |
| P1   | fr    | Ecrou  | Rouge  |
| P2   | fr    | Boulon | Vert   |
| P3   | fr    | Vis    | Bleu   |
| P4   | fr    | Vis    | Rouge  |
| P5   | fr    | Came   | Bleu   |
| P6   | fr    | Rouage | Rouge  |
+------+-------+--------+--------+
```

Also, our RESTful interface must support a `lang` request parameter that allows specifying in which language the data must be served. For instance, making a request at `http://my-sap.com/suppliers/S1?lang=fr` must yield the result below. Everything is kept unchanged but part names and colors that are now in french. Why should the source code change much?

```
+------+-------+---------+--------+-----------------------------------+
| :sid | :name | :status | :city  | :supplies                         |
+------+-------+---------+--------+-----------------------------------+
| S1   | Smith |      20 | London | +------+------+--------+--------+ |
|      |       |         |        | | :pid | :qty | :pname | :color | |
|      |       |         |        | +------+------+--------+--------+ |
|      |       |         |        | | P1   |  300 | Ecrou  | Rouge  | |
|      |       |         |        | | P2   |  200 | Boulon | Vert   | |
|      |       |         |        | | P3   |  400 | Vis    | Bleu   | |
|      |       |         |        | | P4   |  200 | Vis    | Rouge  | |
|      |       |         |        | | P5   |  100 | Came   | Bleu   | |
|      |       |         |        | | P6   |  100 | Rouage | Rouge  | |
|      |       |         |        | +------+------+--------+--------+ |
+------+-------+---------+--------+-----------------------------------+
```

Here you start seriously struggling with a pure SQL approach. Not because the query is difficult to write (it is trivial, in fact), but because SQL provides almost no support for structuring your code. Even with stored procedures and views, you'll have a hard time implementing all requirements in an untangled way so that they can evolve peacefully. Loose coupling and code reuse is not SQL's strenght.

An approach with query builders starts being difficult too. With experience and inversion of control, you'll probably write something maintenable, but you'll have to fight hard (and I'll keep adding requirements). Data internationalization tends to be an ORM killer. Your code will change, for sure.

Let now do it here on try-alf, without changing our original code. 

```try
# I'm the query parameter, change me to 'en'!
def lang_context
  'fr'
end

# Let's rewrite the parts as they were in the current context
def parts(lang = lang_context)
  # hack to simulate the database schema having changed
  ps = project(super(), [:pid, :weight, :city])

  allbut(
    restrict(
      join(ps, parts_i18n),
      lang: lang),
    [:lang])
end

# ORIGINAL CODE UNCHANGED BELOW

def collection
  image(
    suppliers,
    join(
      shipments,
      rename(project(parts, [:pid, :name, :color]), :name => :pname)),
    :supplies)
end

def singular(which_sid)
  restrict(collection, sid: which_sid)
end

singular("S1")
```

The approach demonstrated here is a very good example of what is called [logical data independence](http://www.revision-zero.org/logical-data-independence). Roughly, preventing changes in application code (below) when the data schema changes (above). Views, that is, relational expressions allow presenting the previous schema as if it was unchanged. Composability of the relational algebra makes the rest.

This kind of technique is also very useful for conditional inclusion of complex requirements. Alf supports such the approach in a cleaner way than demonstrated here, through so-called context-aware composable database viewpoints implemented with ruby module. Let take another example of viewpoint: suppliers and parts located in London:

```ruby
module SapOnCity
  include Alf::Viewpoint

  # Only suppliers in London
  def suppliers
    restrict(super(), city: "London")
  end

  # Only parts in London
  def parts
    restrict(super(), city: "London")
  end

  # Restore the foreign keys
  def shipments
    matching(matching(super(), suppliers), parts)
  end
end
```

## Step 4: Authentication and context awareness

I don't know your favorite definition of complexity / simplicity but mine would be something like:

> Conjunction (AND) is simple. Disjunction (OR) is complex.

I challenged this definition the past months and I find it robust and enlightening. I'm aware of other definitions that are equally good, such as Rick Hickey's in [Simple made Easy](http://www.infoq.com/presentations/Simple-Made-Easy) (simple is the opposite of entangled) or Bertrand Meyer's in [Agile!](http://www.springer.com/computer/swe/book/978-3-319-05154-3).
