require "../managed_struct"

module GPhoto2
  class CameraFileInfo
    alias Fields = LibGPhoto2::CameraFileInfoFields
    alias Status = LibGPhoto2::CameraFileStatus

    abstract class Base
      # include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfo)

      def fields : Fields
        wrapped.fields
      end

      def field?(field : Fields)
        fields.includes?(field)
      end

      def status : Status?
        wrapped.status if field?(:status)
      end

      def size : LibC::UInt64T?
        wrapped.size if field?(:size)
      end

      def type : String?
        String.new wrapped.type.to_unsafe if field?(:type)
      end
    end
  end
end
