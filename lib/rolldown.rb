# frozen_string_literal: true

require_relative "rolldown/version"
require_relative "rolldown/errors"
require_relative "rolldown/backend"
require_relative "rolldown/options"
require_relative "rolldown/chunk"
require_relative "rolldown/asset"
require_relative "rolldown/diagnostic"
require_relative "rolldown/build_result"

begin
  require "rolldown/rolldown"
rescue LoadError
  nil
end

module Rolldown
  class << self
    #: (**untyped) -> Rolldown::BuildResult
    def build(**options)
      strict = options.delete(:strict)
      serialized = Options.serialize(options, Options::KNOWN, "a build")

      BuildResult.from_json(Backend.build(serialized)).validate!(strict: strict ? true : false)
    end

    #: () -> String
    def rolldown_version
      Backend.rolldown_version
    end
  end
end
