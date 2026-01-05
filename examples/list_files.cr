require "../src/gphoto2"

# Recursively list folder contents with extended metadata.

def visit(folder, level = 0)
  files = folder.files

  puts "%s %s" % {
    folder.root? ? "/ (root)".colorize(:red) : folder.path.colorize(:green),
    "(#{files.size} files)".colorize(:dark_gray),
  }

  files.each do |file|
    name = file.name
    info = file.info.file
    # Avoid using `CameraFile#size` here to prevent having to load the data along with it.
    size = info.size.try(&.humanize_bytes) || "-"
    type = info.type || "-"
    mtime = info.mtime.try(&.to_s("%Y-%m-%d %H:%M:%S")) || "-"

    if info.readable? || info.removable?
      flags = String.build do |str|
        str << '['
        str << 'R' if info.readable?
        str << 'W' if info.removable?
        str << ']'
      end
    end
    flags ||= "-"

    if info.width && info.height
      dimensions = "#{info.width} x #{info.height}"
    end
    dimensions ||= "-"

    puts "%s  %s  %s  %s  %s  %s" % {
      name.ljust(30).colorize(:blue),
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
