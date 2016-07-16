require "../src/gphoto2"

# Capture an image only after successfully autofocusing.
#
# Typically, if the camera fails to autofocus, updating the `autofocusdrive`
# key will throw an "Unspecified error (-1)". This catches the exception and
# continues to autofocus until it is successful.

GPhoto2::Camera.first do |camera|
  loop do |i|
    begin
      camera.update(autofocusdrive: true)
    rescue GPhoto2::Error
      puts "autofocus failed... retrying"
      camera.reload
      next
    end
    camera.update(autofocusdrive: false)
    break
  end
  camera.capture
end
