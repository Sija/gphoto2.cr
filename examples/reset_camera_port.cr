require "../src/gphoto2"

# Reset port on first found camera

GPhoto2::Camera.first do |camera|
  puts "Resetting %s on port %s" % [
    camera.model.colorize(:green),
    camera.port.colorize(:blue),
  ]
  camera.with_port do |port|
    camera.exit
    port.reset
  end
end
