require "./struct"

module GPhoto2
  class CameraFile
    include GPhoto2::Struct(LibGPhoto2::CameraFile)

    # The preview data is assumed to be a jpg.
    PREVIEW_FILENAME = "capture_preview.jpg"

    IMAGE_EXTENSIONS = %w(jpg jpeg cr2 raw)
    AUDIO_EXTENSIONS = %w(mp3 aae)
    VIDEO_EXTENSIONS = %w(mov)

    @folder : String?
    getter :folder

    @name : String?
    getter :name

    @camera : Camera
    @data_and_size : Tuple(LibC::Char*, LibC::ULong)?

    def initialize(@camera, @folder = nil, @name = nil)
      new
    end

    def finalize : Void
      free
    end

    def preview?
      @folder.nil? && @name.nil?
    end

    def save(pathname = default_filename)
      File.open pathname, "w", &.write(to_slice)
    end

    def delete
      @camera.delete(self)
    end

    def data : LibC::Char*
      data_and_size.first
    end

    def size : LibC::ULong
      data_and_size.last
    end

    def to_slice : Slice(LibC::Char)
      data.to_slice(size)
    end

    def extname : String?
      File.extname(@name)[1..-1].downcase if @name
    end

    def image?
      IMAGE_EXTENSIONS.includes? extname
    end

    def audio?
      AUDIO_EXTENSIONS.includes? extname
    end

    def video?
      VIDEO_EXTENSIONS.includes? extname
    end

    def jpg?
      (extname =~ /jpe?g$/i) != nil
    end

    def_equals @camera, @folder, @name

    private def new
      GPhoto2.check! LibGPhoto2.gp_file_new(out ptr)
      self.ptr = ptr
    end

    private def free
      GPhoto2.check! LibGPhoto2.gp_file_free(self)
    end

    private def default_filename
      preview? ? PREVIEW_FILENAME : @name.not_nil!
    end

    private def data_and_size : Tuple(LibC::Char*, LibC::ULong)
      @data_and_size ||= begin
        @camera.file(self) unless preview?
        get_data_and_size
      end
    end

    private def get_data_and_size : Tuple(LibC::Char*, LibC::ULong)
      GPhoto2.check! LibGPhoto2.gp_file_get_data_and_size(self, out data, out size)
      {data, size}
    end
  end
end
