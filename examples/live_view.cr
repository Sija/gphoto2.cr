require "../src/gphoto2"

# Run and pipe to a video player that can demux raw mjpeg. For example,
#
#     crystal live_view.cr | mpv --demuxer-lavf-format=mjpeg -

# Automatically flush the IO buffer.
STDOUT.sync = true

GPhoto2::Camera.first do |camera|
  loop do
    file = camera.preview
    # Write the preview image to stdout (without copying it first)
    file.write_to(STDOUT)
    # Free the image data right away, since it's allocated outside
    # of the GC heap, and therefore doesn't trigger garbage collection
    file.close
  end
end
