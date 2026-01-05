require "../src/gphoto2"

# Recursively save all files from the camera

DEST_PATH = "pictures"

def visit(camera, folder)
  files = folder.files

  unless files.empty?
    puts folder.path.colorize(:green)

    files.each do |file|
      puts "Saving %s/%s ..." % {
        file.folder.colorize(:green),
        file.name.colorize(:blue),
      }
      path = Path[DEST_PATH, camera.model, file.path]
      file.save path
    end

    puts "Saved #{files.size} files".colorize(:dark_gray)
    puts
  end

  folder.folders.each do |child|
    visit(camera, child)
  end
end

GPhoto2::Camera.first do |camera|
  visit(camera, camera.filesystem)
end
