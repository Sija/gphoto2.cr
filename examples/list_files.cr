require "../src/gphoto2"

# Returns the columns describing the given *file*, using `-` for the
# metadata not reported by the camera.
private def file_columns(file)
  # Avoid using `CameraFile#size` here to prevent having to load the data along with it.
  info = file.info.file?

  size = info.try(&.size).try(&.humanize_bytes)
  type = info.try(&.type)
  mtime = info.try(&.mtime).try(&.to_s("%Y-%m-%d %H:%M:%S"))

  if info && info.field?(:permissions)
    flags = String.build do |str|
      str << '['
      str << 'R' if info.readable?
      str << 'W' if info.removable?
      str << ']'
    end
  end

  if info && (width = info.width) && (height = info.height)
    dimensions = "#{width} x #{height}"
  end

  {size, type, flags, dimensions, mtime}.map { |column| column || "-" }
end

# Recursively list folder contents with extended metadata.
def visit(folder, level = 0)
  files = folder.files

  puts "%s %s" % {
    folder.root? ? "/ (root)".colorize(:red) : folder.path.colorize(:green),
    "(#{files.size} files)".colorize(:dark_gray),
  }

  files.each do |file|
    size, type, flags, dimensions, mtime = file_columns(file)

    puts "%s  %s  %s  %s  %s  %s" % {
      file.name.ljust(30).colorize(:blue),
      type.ljust(25).colorize(:magenta),
      flags.ljust(5).colorize(:cyan),
      size.rjust(12).colorize(:yellow),
      dimensions.rjust(12).colorize(:dark_gray),
      mtime.colorize(:green),
    }
  end

  puts

  folder.folders.each do |child|
    visit(child, level + 1)
  end
end

GPhoto2::Camera.first do |camera|
  visit(camera.filesystem)
end
