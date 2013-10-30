task :man do
  MAN =  Path.dir.parent/'man'
  require 'alf/doc/to_markdown'
  require 'md2man'
  require 'md2man/roff/engine'

  # API
  MAN.mkdir_p
  Alf::Doc.each_api do |kind, name, obj|
    target = MAN/"#{name}.man"
    puts "#{name} -> #{target}"
    md = Alf::Doc::ToMarkdown.new.send(kind, obj)
    target.write(Md2Man::Roff::ENGINE.render(md))
  end
end
