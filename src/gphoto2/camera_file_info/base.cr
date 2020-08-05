require "../managed_struct"

module GPhoto2
  alias CameraFileInfoFields = LibGPhoto2::CameraFileInfoFields
  alias CameraFileStatus = LibGPhoto2::CameraFileStatus

  class CameraFileInfo
    abstract class Base
      # include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfo)

      def fields : CameraFileInfoFields
        wrapped.fields
      end

      def field?(field : CameraFileInfoFields)
        fields.includes?(field)
      end

      def status : CameraFileStatus?
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
