require "../src/gphoto2"

# Lists all libgphoto2 error codes
#
# See:
# - http://gphoto.org/doc/api/gphoto2-port-result_8h.html
# - http://gphoto.org/doc/api/gphoto2-result_8h.html

UNKNOWN_ERROR = "Unknown error"

(-1000..0)
  .each do |code|
    err = GPhoto2.result_as_string(code)
    next if err == UNKNOWN_ERROR

    puts "%s => %s" % {
      code.to_s.rjust(7).colorize(:green),
      err.colorize(:dark_gray),
    }
  end
