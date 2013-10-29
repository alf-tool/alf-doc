require 'wlang'
module Alf
  module Doc
    class ToMarkdown

      TEMPLATES = Path.backfind('templates')

      def operator(op)
        to_markdown(TEMPLATES/"operator.wlang", op)
      end

      def aggregator(op)
        to_markdown(TEMPLATES/"aggregator.wlang", op)
      end

      def predicate(op)
        to_markdown(TEMPLATES/"predicate.wlang", op)
      end

    private

      def to_markdown(tpl, context)
        WLang::Html.render(tpl, context)
      end

    end # class ToMarkdown
  end # module Doc
end # module Alf
