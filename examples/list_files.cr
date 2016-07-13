require "../src/gphoto2"

# Recursively list folder contents with extended metadata.

MAGNITUDES = %w[bytes KiB MiB GiB]

def format_filesize(size, precision = 1)
  n = 0

  while size >= 1024.0 && n < MAGNITUDES.size
    size /= 1024.0
    n += 1
  end

  "%.#{precision}f %s" % [size, MAGNITUDES[n]]
end

def visit(folder, level = 0)
  files = folder.files
  puts \
    "#{folder.root? ? "/ (root)".colorize(:red) : folder.path.colorize(:green)} " \
    "#{"(#{files.size} files)".colorize(:dark_gray)}"

  files.each do |file|
    name = file.name.not_nil!
    info = file.info

    unless info
      puts name.ljust(30).colorize(:blue)

    else
      flags = ""
      if info.readable? || info.deletable?
        flags += 'R' if info.readable?
        flags += 'D' if info.deletable?
        flags = "[#{flags}]"
      end

      dimensions = "-"
      if info.width && info.height
        dimensions = "#{info.width} x #{info.height}"
      end

      # Avoid using `File#size` here to prevent having to load the data along with it.
      size = format_filesize(info.size)
      mtime = info.mtime.to_s("%Y-%m-%d %H:%M:%S")
      type = info.type || "-"

      puts \
        "#{name.ljust(30).colorize(:blue)}  " \
        "#{type.ljust(25).colorize(:magenta)}  " \
        "#{flags.ljust(5).colorize(:cyan)}  " \
        "#{size.rjust(12).colorize(:yellow)}  " \
        "#{dimensions.rjust(12).colorize(:dark_gray)}  " \
        "#{mtime.colorize(:green)}"
    end
  end

  puts

  folder.folders.each { |child| visit(child, level + 1) }
end

GPhoto2::Camera.first do |camera|
  visit(camera.filesystem)
end
