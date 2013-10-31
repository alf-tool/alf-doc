namespace :html do
  require "alf/doc/to_html"

  ROOT = Path.dir.parent
  HTML = ROOT/'compiled/html'

  desc "Generates all API in html"
  task :api do
    # API
    (HTML/'api').mkdir_p
    Alf::Doc.each_api do |kind, name, obj|
      target = HTML/"api/#{name}.html"
      puts "#{name} -> #{target}"
      target.write Alf::Doc::ToHtml.new.send(kind, obj)
    end
  end

  desc "Generates pages in HTML"
  task :pages do
    (HTML/'pages').mkdir_p
    Alf::Doc.pages.each do |page|
      target = HTML/"pages/#{page.rm_ext.basename}.html"
      puts "#{page} -> #{target}"
      target.write(Alf::Doc::ToHtml.new.page(page.read))
    end
  end

  desc "Generates blog in HTML"
  task :blog do
    (HTML/'blog').mkdir_p
    Alf::Doc.blog.each do |page|
      target = HTML/"blog/#{page.rm_ext.basename}.html"
      puts "#{page} -> #{target}"
      target.write(Alf::Doc::ToHtml.new.page(page.read))
    end
  end
end
desc "Generates all HTML pages"
task :html => [:"html:api", :"html:pages", :"html:blog"]