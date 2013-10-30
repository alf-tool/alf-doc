require 'arel'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => "../../sap.db"
)

Arel::Table.engine = Arel::Sql::Engine.new(ActiveRecord::Base)

location  = 'London'
suppliers = Arel::Table.new(:suppliers)
qry = suppliers
    .project(suppliers[:name], suppliers[:city])
    .where(suppliers[:city].eq(location))
puts qry.to_sql

suppliers = Arel::Table.new(:suppliers)
cities    = Arel::Table.new(:cities)
qry = suppliers
    .project(suppliers[:name], suppliers[:city])
    .join(cities)
puts qry.to_sql

suppliers = Arel::Table.new(:suppliers)
supplies  = Arel::Table.new(:supplies)
suppliers.where(supplies.where(suppliers[:sid].eq(supplies[:sid])).exists.not)
