# 0.7.0
- New `CameraFile#read`
- New `CameraFolder#delete`
- New `Camera::Info` module containing `#{about,manual,summary}_text` methods
- Extended `CameraFolder#clear` method to remove subfolders too (off by default)
- Moved all `CameraFileInfo*` classes under single `CameraFileInfo` namespace
- Moved all `CameraWidget*` classes under single `CameraWidget` namespace
- Made camera widgets inherit from `CameraWidget::Base` class
- Changed `CameraWidget::Text` to accept `Number` values, not only `Int` or `Float`
- Changed `CameraWidget::Radio#choices` signature to return non-nillable `String` values
- Changed `CameraFile#info` signature to return non-nillable `CameraFileInfo` value

# 0.6.0
- Code compiles on Crystal v0.19, which is now minimum required version
- New `GPhoto2::Port` class to allow camera port reset
- New `Camera#with_port` convenience method yielding opened camera port instance
- Fixed `GPhoto2#log` macro not showing caller when compiled with --release flag
- Refactored some methods to avoid closures
- Removed CoC, see https://github.com/domgetter/NCoC

# 0.5.0
- Fixed some of the most egregious memory leaks – think: `CameraFile#data`
- Renamed `CameraFile#extname` to `#extension`
- New `CameraFile#path` as a shortcut for `File.join(file.folder, file.name)`
- New `CameraFolder#clear` method which deletes all files in the given folder

# 0.4.0
- New non-throwing `CameraWidget#as_<widget>?` method
- New `CameraAbilities` convenience methods: `#status`, `#device_type`, `#operations`, `#file_operations`, `#folder_operations`
- New `Context#{idle,cancel,error,status,message}_callback` assignable property
- New `Context#check!` for context-aware error messages
- New `CameraAbilitiesList#[model : String]`
- New `PortInfoList#[port : String]`
- New `PortInfoList#type`
- Optimized `Camera.all` method (shaved ~5s)
- Removed method aliases `CameraAbilitiesList#{index,at}`, `PortInfoList#{index,at}`, `CameraList#length`
- Changed some of the nillable methods to return non-nillable types with `#not_nil!`

# 0.3.1
- `CameraWidget+#value=` throws when passed an unsupported value type
- `Camera#unref` nullifies `self.ptr`

# 0.3.0
- New non-throwing `Camera#[]?` version of `Camera#[]`
- New `Camera#preserving_config`
- New `CameraWidget#==(other : self | String | Symbol | Regex)`
- New `CameraWidget#readonly?`
- New `CameraWidget#id`
- New `CameraWidget#info`
- New `CameraWidget#in?`
- `CameraWidget#value=` accepts `String` values for most of the widget types
- `RadioCameraWidget#value=(value : Regex)` sets first matching option from `#choices`
- New `RadioCameraWidget#move_by(step : Int)` along with `#<<` and `#>>` operators
- New `ButtonCameraWidget`, refs #15
- Lots of bugfixes and optimizations
- [Code of Conduct](contributor-covenant.org/version/1/4/)

# 0.2.0
- New `Exception` class as a catch-all for the whole namespace…
- New `ManagedStruct` to handle allocation of structs passed from `gp_*` functions
- New `CameraFile#info`
- New `Camera#autorelease` convenience method
- `Camera#update` accepts `**kwargs`
- `CameraFile#save` creates destination directory if needed
- `Camera` initialization is now lazy
- Fixed `RangeCameraWidget#range`
- File listing example to shows basic metadata for every file listed
- New file saving example

# 0.1.0
### Working features:
- Port enumeration
- Camera selection
- Capture & preview
- Filesystem operations
- Reading abilities
- Reading and writing config
- Events—like waiting for the file being added
- Most of the examples

### Known issues:
- Pointer magic might be wrong here & there
- Memory management related stuff is *WIP*
- Might have memory leaks
