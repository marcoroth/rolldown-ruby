# frozen_string_literal: true

require "json"

module Rolldown
  class Options
    KNOWN = [:input, :cwd, :dir, :file, :format, :name, :platform].freeze #: Array[Symbol]

    #: (Hash[Symbol, untyped], ?Array[Symbol], ?String) -> String
    def self.serialize(options, allowed = KNOWN, subject = "a build")
      new(options, allowed, subject).to_json
    end

    attr_reader :options #: Hash[Symbol, untyped]

    #: (Hash[Symbol, untyped], ?Array[Symbol], ?String) -> void
    def initialize(options, allowed = KNOWN, subject = "a build")
      @options = normalize(options)

      validate!(allowed, subject)

      freeze
    end

    #: () -> Hash[Symbol, untyped]
    def to_h
      options
    end

    #: (?untyped) -> String
    def to_json(state = nil)
      state ? JSON.generate(to_h, state) : JSON.generate(to_h)
    end

    #: () -> String
    def inspect
      "#<#{self.class.name} #{to_h.inspect}>"
    end

    private

    #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
    def normalize(given)
      normalized = given.compact

      normalized[:input] = entries(normalized[:input]) if normalized.key?(:input)
      normalized[:format] = normalized[:format].to_s if normalized.key?(:format)
      normalized[:platform] = normalized[:platform].to_s if normalized.key?(:platform)
      normalized[:cwd] = normalized[:cwd].to_s if normalized.key?(:cwd)

      normalized
    end

    #: (untyped) -> Array[untyped]
    def entries(given)
      list = given.is_a?(Array) ? given : [given]

      list.map { |entry| entry.is_a?(Hash) ? entry : entry.to_s }
    end

    #: (Array[Symbol], String) -> void
    def validate!(allowed, subject)
      unknown = options.keys - allowed

      return if unknown.empty?

      raise OptionError, "#{unknown.first} is not an option for #{subject}"
    end
  end
end
