# gphoto2.cr [![Build Status](https://travis-ci.org/Sija/gphoto2.cr.svg?branch=master)](https://travis-ci.org/Sija/gphoto2.cr)

**gphoto2.cr** provides an FFI for common functions in [libgphoto2][gphoto].
It also includes a facade to interact with the library in a more idiomatic Crystal way.

## Installation

### Prerequisites

  * Crystal >= 0.23.0
  * libgphoto2 >= 2.5.2
  * libgphoto2_port >= 0.10.1

To install the latest libgphoto2, you can use `homebrew` or `apt-get`, depending on the platform:

#### Mac OS X

```
$ brew install libgphoto2
```

#### Debian/Ubuntu

```
$ apt-get install libgphoto2-6 libgphoto2-dev libgphoto2-port10
```

### Shard

Add this to your application's `shard.yml`:

```yaml
dependencies:
  gphoto2:
    github: sija/gphoto2.cr
```

## Usage

```crystal
require "gphoto2"

# list available cameras
cameras = GPhoto2::Camera.all
# => [#<GPhoto2::Camera>, ...]

# list found cameras by model and port path
cameras.map { |c| [c.model, c.port] }
# => [["Nikon DSC D5100 (PTP mode)", "usb:250,006"], ...]

# use the first camera
camera = cameras.first

# ...or more conveniently
camera = GPhoto2::Camera.first

# search by model name
camera = GPhoto2::Camera.where(model: /nikon/i).first

# the above examples require the camera be manually closed when done
camera.close

# pass a block to automatically close the camera
GPhoto2::Camera.first do |camera|
  # ...
end

# ...or use `#autorelease` on any `Camera` instance
camera.autorelease do
  # ...
end

# check camera abilities (see `LibGPhoto2::CameraOperation`)
camera.can? :capture_image
# => true

# list camera configuration names
camera.config.keys
# => ["autofocusdrive", "manualfocusdrive", "controlmode", ...]

# read the current configuration value of an option
camera[:expprogram].value
# => "M"
camera[:whitebalance].value
# => "Automatic"

# compare the current configuration value
camera[:whitebalance] == "Automatic"
camera[:whitebalance] == /Automatic/i
camera[:whitebalance] == :automatic
# => true

# list valid choices of a configuration option
camera[:whitebalance].as_radio.choices
# => ["Automatic", "Daylight", "Fluorescent", "Tungsten", ...]

# check if the configuration has changed
camera.dirty?
# => false

# change camera configuration
camera["iso"] = 800
camera["f-number"] = "f/4.5"
camera["shutterspeed2"] = "1/30"

# set radio widget value to first matching option
camera[:imageformat] = /Medium(.+?)JPEG/i

# check if the configuration has changed
camera.dirty?
# => true

# apply the new configuration to the device
camera.save

# alternatively, update the camera configuration in one go
camera.update({ iso: 200, shutterspeed2: "1/60", "f-number": "f/1.8" })

# ...do all of above while preserving camera original configuration
camera.preserving_config do
  # ...
end

# take a photo
file = camera.capture

# ...and save it to the current working directory
file.save

# ...or to a specific pathname
file.save("/tmp/out.jpg")

# traverse the camera filesystem
folder = camera/"store_00010001/DCIM/100D5100"

# list files
files = folder.files
folder.files.map(&.name)
# => ["DSC_0001.JPG", "DSC_0002.JPG", ...]

# copy a file from the camera
file = files.first
file.save

# ...and then delete it from the camera
file.delete
```

More examples can be found in [`examples/`][examples]. Documentation can be generated using `crystal doc` task or [browsed online][docs].

[gphoto]: http://www.gphoto.org/
[examples]: https://github.com/Sija/gphoto2.cr/tree/master/examples
[docs]: https://sija.github.io/gphoto2.cr

## Development

Enable debug mode by passing `DEBUG=1` env variable:
```
DEBUG=1 crystal examples/list_cameras.cr
```

Run specs with:
```
crystal spec
```

## Contributing

1. Fork it ( https://github.com/sija/gphoto2.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Acknowledgements

- The [gphoto2][gphoto] developers for building such an awesome tool
- [@zaeleus](https://github.com/zaeleus) for the [ffi-gphoto2](https://github.com/zaeleus/ffi-gphoto2) gem, on which this library is heavily inspired

## Contributors

- [@Sija](https://github.com/Sija) Sijawusz Pur Rahnama - creator, maintainer
