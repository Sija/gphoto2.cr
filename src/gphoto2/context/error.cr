require "../error"

module GPhoto2
  class Context
    class Error < GPhoto2::Error
      # Creates an error with the *message* reported by libgphoto2
      # (see `Context#check!`), keeping the generic error as its *cause*.
      def initialize(@message : String?, @code : Int32, @cause : GPhoto2::Error)
      end
    end
  end
end
