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
  major, minor, = RUBY_VERSION.split(".")
  require_relative "rolldown/#{major}.#{minor}/rolldown"
rescue LoadError
  require_relative "rolldown/rolldown"
end

module Rolldown
  class << self
    #: (**untyped) -> Rolldown::BuildResult
    def build(**options)
      strict = options.delete(:strict)
      serialized = Options.serialize(options, "a build")

      payload = Backend.build(serialized)

      BuildResult.from_json(payload, destination(options), options[:cwd]&.to_s).validate!(strict: strict ? true : false)
    end

    #: () -> String
    def rolldown_version
      Backend.rolldown_version
    end

    private

    #: (Hash[Symbol, untyped]) -> String?
    def destination(options)
      output = options[:output]

      return nil unless output.is_a?(Hash)

      file = output[:file]

      return File.dirname(file.to_s) if file

      output[:dir]&.to_s
    end
  end
end
