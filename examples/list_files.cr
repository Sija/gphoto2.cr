require "../src/gphoto2"

# List all files in tree form.

def visit(folder, level = 0)
  indent = "  " * level

  files = folder.files
  puts "#{indent}\
    #{folder.root? ? "/ (root)".colorize(:red) : folder.path.colorize(:green)} \
    #{"(#{files.size} files)".colorize(:dark_gray)}"

  folder.folders.each { |child| visit(child, level + 1) }
  indent += "  "

  puts indent + files.map { |file|
    filename = file.name.not_nil!
    "#{filename.sub(/\.(.*?)$/, "").colorize(:blue)}" \
    "#{File.extname(filename).colorize(:light_blue).mode(:bright)}"
  }.join " , "
end

GPhoto2::Camera.first do |camera|
  visit(camera.filesystem)
end
