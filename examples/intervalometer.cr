require "../src/gphoto2"

# Take a photo every 10 seconds for 2 hours.

INTERVAL = 10.seconds
DURATION = 2.hours

GPhoto2::Camera.first do |camera|
  elapsed = Time::Span.zero

  while elapsed < DURATION
    took = Time.measure do
      file = camera.capture
      file.save
    end
    # Account for the capture time, so that photos are evenly spaced
    sleep(INTERVAL - took) if took < INTERVAL
    elapsed += {took, INTERVAL}.max
  end
end
