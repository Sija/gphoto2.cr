require "../managed_struct"

module GPhoto2
  # Represents file information.
  class CameraFileInfo
    alias Fields = LibGPhoto2::CameraFileInfoFields
    alias Status = LibGPhoto2::CameraFileStatus

    abstract class Base
      # include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfo)

      def fields : Fields
        wrapped.fields
      end

      # Returns `true` if the given *field* is set, `false` otherwise.
      def field?(field : Fields)
        fields.includes?(field)
      end

      def status : Status?
        wrapped.status if field?(:status)
      end

      # Returns the size of the file in bytes.
      def size : UInt64?
        wrapped.size.to_u64 if field?(:size)
      end

      # Returns the type of the file.
      def type : String?
        String.new wrapped.type.to_unsafe if field?(:type)
      end
    end
  end
end
