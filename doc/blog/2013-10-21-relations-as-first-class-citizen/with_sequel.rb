require 'sequel'

DB = ::Sequel.connect('sqlite://../../sap.db')

# suppliers = DB[:suppliers].select(:sid, :name, :city).where(city: 'London')
# cities    = DB[:cities].select(:city, :country)
# puts suppliers.join(cities).sql

# suppliers = DB[:suppliers]
# cities    = DB[:cities]
# 
# puts DB[:suppliers]
#   .natural_join(:cities)
#   .select(:sid, :name, :city, :country)
#   .where(city: 'London').sql
# 
# puts DB[:suppliers]
#   .select(:sid, :name, :city)
#   .where(city: 'London')
#   .natural_join(:cities).sql
# 
# puts DB[:suppliers]
#   .select(:sid, :name, :city)
#   .where(city: 'London')
#   .natural_join(:cities)
#   .select_more(:country).sql
# 
# def suppliers_in(city)
#   DB[:suppliers]
#     .select(:sid, :name, :city)
#     .where(:city => city)
#     .from_self
# end
# 
# def with_country(operand)
#   cities = DB[:cities].select(:city, :country)
#   operand.natural_join(cities).from_self
# end
# 
# requester_city = 'London' # from context
# puts with_country(suppliers_in(requester_city)).sql
# 

puts DB[:suppliers___s].where(~DB[:supplies___sp].where(Sequel.qualify(:sp, :sid) => (Sequel.qualify(:s, :sid))).exists).sql