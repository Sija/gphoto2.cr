require "../src/gphoto2"

# Lists all found cameras

cameras = GPhoto2::Camera.all # or .where model: /canon/i
cameras.each do |camera|
  abilities = camera.abilities

  puts camera.model.colorize(:green)
  props = {
    "id":                camera.id,
    "port":              camera.port,
    "driver status":     abilities.status,
    "device type":       abilities.device_type,
    "operations":        abilities.operations,
    "file operations":   abilities.file_operations,
    "folder operations": abilities.folder_operations,
  }
  props.each do |prop, value|
    puts "  %s: %s" % [prop, value.to_s.colorize(:blue)]
  end

  camera.close
end
