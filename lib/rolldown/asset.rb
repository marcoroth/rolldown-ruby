# frozen_string_literal: true

module Rolldown
  class Asset
    attr_reader :filename #: String
    attr_reader :names #: Array[String]
    attr_reader :source #: String?

    #: (Hash[String, untyped]) -> Rolldown::Asset
    def self.from_hash(hash)
      new(filename: hash.fetch("filename"), names: hash.fetch("names"), source: hash["source"])
    end

    #: (filename: String, names: Array[String], source: String?) -> void
    def initialize(filename:, names:, source:)
      @filename = filename.freeze
      @names = names.freeze
      @source = source&.freeze

      freeze
    end

    #: () -> String
    def to_s
      source.to_s
    end

    #: () -> String
    def inspect
      "#<#{self.class.name} #{filename.inspect}#{" #{source.bytesize} bytes" if source}>"
    end
  end
end
