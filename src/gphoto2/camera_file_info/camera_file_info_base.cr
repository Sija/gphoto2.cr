require "../managed_struct"

module GPhoto2
  class CameraFileInfo
    abstract class Base
      # include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfo)

      def fields
        wrapped.fields
      end

      def has_field?(field : String | Symbol)
        fields.includes? LibGPhoto2::CameraFileInfoFields.parse(field.to_s)
      end

      def status : LibGPhoto2::CameraFileStatus?
        wrapped.status if has_field?(:status)
      end

      def size : LibC::UInt64T?
        wrapped.size if has_field?(:size)
      end

      def type : String?
        String.new wrapped.type.to_unsafe if has_field?(:type)
      end
    end
  end
end
