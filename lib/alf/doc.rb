require_relative 'doc/version'
require_relative 'doc/loader'
require_relative 'doc/viewpoint'
module Alf
  module Doc

    ROOT = Path.dir.parent.parent

    DOC_ROOT = ROOT/"doc"

    DB = Alf.connect(Path.dir, viewpoint: Viewpoint[])

    def self.query(*args, &bl)
      DB.query(*args, &bl)
    end

    def self.all
      query{
        extend(Relation::DEE,
          predicates: predicates,
          operators: operators,
          aggregators: aggregators,
          examples: examples)
      }
    end

    def self.examples
      query{ examples }
    end

    def self.pages
      (ROOT/'pages').glob("*.md")
    end

  end # module Doc
end # module Alf
