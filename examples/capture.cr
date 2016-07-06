require "../src/gphoto2"

# Captures a single photo and saves it to the current working directory.

GPhoto2::Camera.first do |camera|
  unless camera.can?(:capture_image)
    GPhoto2.logger.warn %Q("#{camera.model}" doesn't support image capture!)
    next
  end
  file = camera.capture
  file.save
end
