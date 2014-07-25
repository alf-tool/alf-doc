module Alf
  module Doc
    module Version

      MAJOR = 0
      MINOR = 16
      TINY  = 3

      def self.to_s
        [ MAJOR, MINOR, TINY ].join('.')
      end

    end
    VERSION = Version.to_s
  end
end
