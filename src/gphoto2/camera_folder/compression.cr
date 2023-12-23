require "compress/zip"

module GPhoto2
  class CameraFolder
    module Compression
      private def zip_visitor(zip, folder : CameraFolder, root : String? = nil)
        folder.files.each do |file|
          pathname = root ? Path.posix(root, file.path).to_s : file.path
          pathname = pathname.lchop('/')
          mtime = file.info.file?.try(&.mtime) || Time.local

          entry = Compress::Zip::Writer::Entry.new pathname,
            time: mtime.to_utc

          zip.add entry, file.to_slice
        end

        folder.folders.each do |child|
          zip_visitor(zip, child, root)
        end
      end

      def to_zip_file(io : IO, root : String? = nil) : Nil
        root ||= name

        Compress::Zip::Writer.open(io) do |zip|
          zip_visitor zip, self, root
        end
      end

      def to_zip_file(root : String? = nil) : File
        File.tempfile(prefix: "camera.fs-", suffix: ".zip") do |file|
          to_zip_file(file, root)
        end
      end

      def to_zip_file(root : String? = nil, &) : Nil
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
