require 'wlang'
require 'albino'
require 'redcarpet'
require 'base64'
require_relative 'to_markdown'
module Alf
  module Doc
    class ToHtml

      class HTMLwithAlbino < Redcarpet::Render::HTML
        def block_code(code, language)
          Albino.colorize(code, language || :ruby)
        end
      end

      def operator(op)
        to_html(ToMarkdown.new.operator(op))
      end

      def aggregator(op)
        to_html(ToMarkdown.new.aggregator(op))
      end

      def predicate(op)
        to_html(ToMarkdown.new.predicate(op))
      end

      def page(md)
        to_html(md)
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

    end # class ToHtml
  end # module Doc
end # module Alf
