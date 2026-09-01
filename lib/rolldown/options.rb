# frozen_string_literal: true

require "json"

module Rolldown
  class Options
    INPUT = [:input, :cwd, :external, :platform, :treeshake, :shim_missing_exports].freeze #: Array[Symbol]

    OUTPUT = [
      :dir, :file, :format, :name, :exports, :sourcemap, :minify, :banner, :footer, :intro, :outro,
      :entry_file_names, :chunk_file_names, :asset_file_names, :keep_names, :legal_comments, :es_module
    ].freeze #: Array[Symbol]

    TRANSFORM = [:define].freeze #: Array[Symbol]

    KNOWN = (INPUT + [:output, :transform]).freeze #: Array[Symbol]

    CALLABLE = {
      plugins: "plugins",
      on_log: "onLog",
      manual_chunks: "manualChunks",
      sourcemap_path_transform: "sourcemapPathTransform",
    }.freeze #: Hash[Symbol, String]

    #: (Hash[Symbol, untyped], ?String) -> String
    def self.serialize(options, subject = "a build")
      new(options, subject).to_json
    end

    attr_reader :options #: Hash[Symbol, untyped]

    #: (Hash[Symbol, untyped], ?String) -> void
    def initialize(options, subject = "a build")
      @options = normalize(options)

      validate!(subject)

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
      output = (normalized[:output] || {}).compact

      normalized[:input] = entries(normalized[:input]) if normalized.key?(:input)
      normalized[:external] = externals(normalized[:external]) if normalized.key?(:external)
      normalized[:cwd] = normalized[:cwd].to_s if normalized.key?(:cwd)
      normalized[:platform] = normalized[:platform].to_s if normalized.key?(:platform)

      [:format, :exports, :legal_comments].each do |key|
        output[key] = output[key].to_s if output.key?(key)
      end

      [:sourcemap, :minify].each do |key|
        output[key] = output[key].to_s if output[key].is_a?(Symbol)
      end

      normalized[:output] = output
      normalized[:transform] = (normalized[:transform] || {}).compact

      normalized
    end

    #: (untyped) -> Array[untyped]
    def entries(given)
      return named(given) if given.is_a?(Hash)

      list = given.is_a?(Array) ? given : [given]

      list.map { |entry| entry.is_a?(Hash) ? entry : entry.to_s }
    end

    #: (untyped) -> Array[String]
    def externals(given)
      list = given.is_a?(Array) ? given : [given]

      list.map(&:to_s)
    end

    #: (Symbol, Array[Symbol], String) -> void
    def refuse_nested(group, allowed, subject)
      unknown = nested_keys(group) - allowed

      return if unknown.empty?

      raise OptionError, "#{group}.#{unknown.first} is not an option for #{subject}"
    end

    #: (Symbol) -> Array[Symbol]
    def nested_keys(group)
      value = options[group]

      value.is_a?(Hash) ? value.keys : []
    end

    #: () -> Array[Symbol]
    def output_keys
      output = options[:output]

      output.is_a?(Hash) ? output.keys : []
    end

    #: (Hash[untyped, untyped]) -> Array[untyped]
    def named(given)
      given.map { |name, import| { name: name.to_s, import: import.to_s } }
    end

    #: (String) -> void
    def validate!(subject)
      refuse_callables

      unknown = options.keys - KNOWN

      raise OptionError, "#{unknown.first} is not an option for #{subject}" unless unknown.empty?

      refuse_nested(:output, OUTPUT, subject)
      refuse_nested(:transform, TRANSFORM, subject)
    end

    #: () -> void
    def refuse_callables
      given = options.keys + output_keys + nested_keys(:transform)
      named = CALLABLE.keys.find { |key| given.include?(key) }

      return unless named

      raise OptionError,
            "#{named} takes a JavaScript function, which cannot cross into Ruby. " \
            "See https://rolldown.rs for what #{CALLABLE.fetch(named)} does."
    end
  end
end
