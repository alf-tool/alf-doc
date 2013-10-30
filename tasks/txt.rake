task :txt do
  TXT = Path.dir.parent/'compiled/txt'
  require 'alf/doc/to_markdown'

  # API
  TXT.mkdir_p
  Alf::Doc.each_api do |kind, name, obj|
    target = TXT/"#{name}.txt"
    puts "#{name} -> #{target}"
    md = Alf::Doc::ToMarkdown.new.send(kind, obj)
    target.write(md.gsub(/^```(try)?\n/, ""))
  end
end
