require "../src/gphoto2"

# Capture an image only after successfully autofocusing.
#
# Typically, if the camera fails to autofocus, updating the `autofocusdrive`
# key will throw an "Unspecified error (-1)". This catches the exception and
# continues to autofocus until it is successful.

GPhoto2::Camera.first do |camera|
  loop do |i|
    begin
      camera.update({ autofocusdrive: true })
    rescue GPhoto2::Error
      if i >= 9
        puts "autofocus reached 10 failed attempts, bailing out..."
        break
      end
      puts "autofocus failed... retrying"
      camera.reload
    ensure
      camera.update({ autofocusdrive: false })
    end
    break
  end
  camera.capture
end
