require "../src/gphoto2"

# Take a photo every 10 seconds for 2 hours.

INTERVAL  = 10.seconds
STOP_TIME = Time.monotonic + 2.hours

GPhoto2::Camera.first do |camera|
  until Time.monotonic >= STOP_TIME
    file = camera.capture
    file.save
    sleep INTERVAL
  end
end
