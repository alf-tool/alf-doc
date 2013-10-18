module Alf
  module Doc
    module Viewpoint
      include Alf::Viewpoint

      def aggregators
        @aggregators ||= load_file("aggregators")
      end

      def operators
        @operators ||= load_file("operators")
      end

      def predicates
        @predicates ||= load_file("predicates")
      end

    private

      def load_file(who)
        folder = Doc::DOC_ROOT/who
        tuples = folder.glob('*.yml').map(&:load)
        Relation(tuples)
      end

    end # class Viewpoint
  end # module Doc
end # module Alf
