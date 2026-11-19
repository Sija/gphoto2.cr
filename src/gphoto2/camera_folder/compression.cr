require "compress/zip"

module GPhoto2
  class CameraFolder
    # Provides methods to compress the contents of the folder.
    module Compression
      private def zip_visitor(zip, folder : CameraFolder, root : String? = nil)
        folder.files.each do |file|
          # Store entries relative to the compressed folder
          pathname = file.path.relative_to(path)
          pathname = Path.posix(root, pathname) if root
          pathname = pathname.to_s.lchop('/')

          mtime = file.info.file?.try(&.mtime) ||
                  Time.local

          # ZIP format stores (time zone-less) MS-DOS timestamps,
          # which are interpreted as local time by the extracting tools
          entry = Compress::Zip::Writer::Entry.new pathname,
            time: dos_time(mtime.to_local)

          begin
            zip.add entry, file.raw_slice
          ensure
            # free the downloaded data right away, instead of waiting for the GC
            file.close
          end
        end

        folder.folders.each do |child|
          zip_visitor(zip, child, root)
        end
      end

      # MS-DOS timestamps can represent years 1980-2107 only, while
      # cameras with an unset clock might report i.e. 1970.
      private def dos_time(time : Time) : Time
        case time.year
        when .< 1980
          Time.local(1980, 1, 1, location: time.location)
        when .> 2107
          Time.local(2107, 12, 31, 23, 59, 58, location: time.location)
        else
          time
        end
      end

      # Writes the compressed contents of the folder to *io*.
      def to_zip_file(io : IO, root : String? = nil) : Nil
        root ||= name

        Compress::Zip::Writer.open(io) do |zip|
          zip_visitor zip, self, root
        end
      end

      # Returns a temporary file with the compressed contents of the folder.
      def to_zip_file(root : String? = nil) : File
        tempfile = File.tempfile(prefix: "camera.fs-", suffix: ".zip")
        begin
          to_zip_file(tempfile, root)
        rescue ex
          # Don't leave a partially written file behind
          tempfile.close
          tempfile.delete
          raise ex
        end
        tempfile.tap(&.close)
      end

      # Yields a temporary file with the compressed contents of the folder.
      #
      # Returns the value of the block.
      #
      # NOTE: the temporary file will be deleted after the block returns.
      def to_zip_file(root : String? = nil, &)
        tempfile = to_zip_file(root)
        begin
          yield tempfile
        ensure
          tempfile.delete
        end
      end
    end
  end
end
