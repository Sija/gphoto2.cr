require "../error"

module GPhoto2
  class Context
    class Error < GPhoto2::Error
      def initialize(@message : String?, @code : Int32, @cause : GPhoto2::Error)
      end
    end
  end
end
