require "../src/gphoto2"

# Take a photo every 10 seconds for 2 hours.

interval = 10.seconds
stop_time = Time.now + 2.hours

GPhoto2::Camera.first do |camera|
  until Time.now >= stop_time
    camera.capture.save
    sleep interval
  end
end
