# frozen_string_literal: true

require "json"

module Rolldown
  class BuildResult
    attr_reader :chunks #: Array[Rolldown::Chunk]
    attr_reader :assets #: Array[Rolldown::Asset]
    attr_reader :warnings #: Array[Rolldown::Diagnostic]
    attr_reader :errors #: Array[Rolldown::Diagnostic]

    #: (String) -> Rolldown::BuildResult
    def self.from_json(payload)
      parsed = JSON.parse(payload)

      new(
        chunks: parsed.fetch("chunks").map { |chunk| Chunk.from_hash(chunk) },
        assets: parsed.fetch("assets").map { |asset| Asset.from_hash(asset) },
        warnings: parsed.fetch("warnings").map { |warning| Diagnostic.from_hash(warning) },
        errors: parsed.fetch("errors").map { |error| Diagnostic.from_hash(error) },
        failed: parsed.fetch("failed")
      )
    end

    #: (chunks: Array[Rolldown::Chunk], assets: Array[Rolldown::Asset], warnings: Array[Rolldown::Diagnostic], errors: Array[Rolldown::Diagnostic], failed: bool) -> void
    def initialize(chunks:, assets:, warnings:, errors:, failed:)
      @chunks = chunks.freeze
      @assets = assets.freeze
      @warnings = warnings.freeze
      @errors = errors.freeze
      @failed = failed

      freeze
    end

    #: () -> bool
    def failed?
      @failed
    end

    #: () -> bool
    def errors?
      !errors.empty?
    end

    #: () -> bool
    def warnings?
      !warnings.empty?
    end

    #: () -> Rolldown::Chunk?
    def entry
      chunks.find(&:entry?)
    end

    #: (?strict: bool) -> Rolldown::BuildResult
    def validate!(strict: false)
      raise BuildError, errors.map(&:message).join("\n\n") if failed? || errors?
      raise BuildError, warnings.map(&:message).join("\n\n") if strict && warnings?

      self
    end

    #: () -> String
    def to_s
      chunks.map(&:code).join("\n")
    end

    #: () -> String
    def inspect
      parts = ["chunks=#{chunks.length}"]
      parts << "assets=#{assets.length}" unless assets.empty?
      parts << "warnings=#{warnings.length}" unless warnings.empty?
      parts << "errors=#{errors.length}" unless errors.empty?
      parts << "failed" if failed?

      "#<#{self.class.name} #{parts.join(" ")}>"
    end
  end
end
