require 'wlang'
require 'albino'
require 'redcarpet'
require 'base64'
module Alf
  module Doc
    class ToHtml

      TEMPLATES = Path.backfind('templates')

      class HTMLwithAlbino < Redcarpet::Render::HTML
        def block_code(code, language)
          Albino.colorize(code, language || :ruby)
        end
      end

      def operator(op)
        to_html(to_markdown(TEMPLATES/"operator.wlang", op))
      end

      def aggregator(op)
        to_html(to_markdown(TEMPLATES/"aggregator.wlang", op))
      end

      def predicate(op)
        to_html(to_markdown(TEMPLATES/"predicate.wlang", op))
      end

      def page(md)
        to_html(md)
      end

    private

      def to_markdown(tpl, context)
        WLang::Html.render(tpl, context)
      end

      def to_html(src)
        src = src.gsub(/([ ]*)```try\n(.*?)\n([ ]*)```/m){|m|
          spacing = $1 || ""
          source  = $2.strip.gsub(/^#{spacing}/, "")
          quoted  = Base64.encode64(source)
          source  = "```\n#{source}\n```"
          source  = source.gsub(/^/, spacing)
          %Q{#{source}\n<div class="try-this"><a href="/?src=#{quoted}" target="_blank">Try it!</a></div>}
        }
        options = {:fenced_code_blocks => true}
        Redcarpet::Markdown.new(HTMLwithAlbino, options).render(src)
      end

    end # class Markdowner
  end # module Doc
end # module Alf
