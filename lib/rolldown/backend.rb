# frozen_string_literal: true

module Rolldown
  module Backend
    module Unavailable
      #: (String) -> String
      def build(_options_json)
        unavailable(__method__)
      end

      #: () -> String
      def panic_for_test
        unavailable(__method__)
      end

      #: () -> String
      def version
        unavailable(__method__)
      end

      #: () -> String
      def rolldown_version
        unavailable(__method__)
      end

      private

      #: (Symbol?) -> bot
      def unavailable(name)
        raise NotImplementedError, "Rolldown::Backend.#{name} is defined by the native extension, which did not load"
      end
    end

    extend Unavailable
  end
end
