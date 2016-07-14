require "../src/gphoto2"

# Lists all libgphoto2 error codes
# See:
# - http://gphoto.org/doc/api/gphoto2-port-result_8h.html
# - http://gphoto.org/doc/api/gphoto2-result_8h.html

(-1000..0)
  .map    { |code| {code, GPhoto2.result_as_string code} }
  .reject { |code, err| err == "Unknown error" }
  .each   { |code, err|
    puts "#{code.to_s.rjust(7).colorize(:green)} => #{err.colorize(:dark_gray)}"
  }
