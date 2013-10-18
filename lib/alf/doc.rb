require_relative 'doc/version'
require_relative 'doc/loader'
require_relative 'doc/viewpoint'
module Alf
  module Doc

    DOC_ROOT = Path.dir.parent.parent/"doc"
    DB = Alf.connect(Path.dir, viewpoint: Viewpoint[])

    def self.query(*args, &bl)
      DB.query(*args, &bl)
    end

    def self.all
      query{
        extend(Relation::DEE,
          predicates: predicates,
          operators: operators,
          aggregators: aggregators)
      }
    end

  end # module Doc
end # module Alf
