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
      (DOC_ROOT/'pages').glob("*.md")
    end

    def self.blog
      (DOC_ROOT/'blog').glob("*.md")
    end

    def self.each_api
      [:operators, :predicates, :aggregators].each do |kind|
        Alf::Doc.query(kind).each do |obj|
          yield(kind.to_s[0...-1].to_sym, obj.name, obj)
        end
      end
    end

  end # module Doc
end # module Alf
