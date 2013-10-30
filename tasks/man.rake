task :man do
  MAN = Path.dir.parent/'compiled/man'
  MAN.mkdir_p
  require 'alf/doc/to_markdown'
  require 'md2man'
  require 'md2man/roff/engine'

  # API
  Alf::Doc.each_api do |kind, name, obj|
    target = MAN/"#{name}.man"
    puts "#{name} -> #{target}"
    md = Alf::Doc::ToMarkdown.new.send(kind, obj)
    target.write(Md2Man::Roff::ENGINE.render(md))
  end

  # COMMANDS
  Alf::Doc.commands.each do |md|
    target = MAN/"#{md.basename.rm_ext}.man"
    puts "#{md} -> #{target}"
    target.write(Md2Man::Roff::ENGINE.render(md.read))
  end
end
