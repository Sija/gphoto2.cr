require "../src/gphoto2"

# Run and pipe to a video player that can demux raw mjpeg. For example,
#
#     crystal live_view.cr | mpv --demuxer-lavf-format=mjpeg -

# Automatically flush the IO buffer.
STDOUT.sync = true

GPhoto2::Camera.first do |camera|
  loop do
    # Write the preview image to stdout.
    STDOUT.write camera.preview.to_slice
  end
end
