desc "Generate .txt pages"
task :txt do
  TXT = Path.dir.parent/'compiled/txt'
  TXT.mkdir_p
  require 'alf/doc/to_markdown'

  # API
  Alf::Doc.each_api do |kind, name, obj|
    target = TXT/"#{name}.txt"
    puts "#{name} -> #{target}"
    md = Alf::Doc::ToMarkdown.new.send(kind, obj)
    target.write(md.gsub(/^```(try)?\n/, ""))
  end

  # COMMANDS
  Alf::Doc.commands.each do |md|
    target = TXT/"#{md.basename.rm_ext}.txt"
    puts "#{md} -> #{target}"
    target.write(md.read)
  end
end
