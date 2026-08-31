# frozen_string_literal: true

module Rolldown
  class Chunk
    attr_reader :filename #: String
    attr_reader :name #: String
    attr_reader :code #: String
    attr_reader :map #: String?
    attr_reader :imports #: Array[String]
    attr_reader :dynamic_imports #: Array[String]
    attr_reader :exports #: Array[String]
    attr_reader :module_ids #: Array[String]

    #: (Hash[String, untyped]) -> Rolldown::Chunk
    def self.from_hash(hash)
      new(
        filename: hash.fetch("filename"),
        name: hash.fetch("name"),
        code: hash.fetch("code"),
        map: hash["map"],
        entry: hash.fetch("is_entry"),
        dynamic_entry: hash.fetch("is_dynamic_entry"),
        imports: hash.fetch("imports"),
        dynamic_imports: hash.fetch("dynamic_imports"),
        exports: hash.fetch("exports"),
        module_ids: hash.fetch("module_ids")
      )
    end

    #: (filename: String, name: String, code: String, map: String?, entry: bool, dynamic_entry: bool, imports: Array[String], dynamic_imports: Array[String], exports: Array[String], module_ids: Array[String]) -> void
    def initialize(filename:, name:, code:, map:, entry:, dynamic_entry:, imports:, dynamic_imports:, exports:, module_ids:)
      @filename = filename.freeze
      @name = name.freeze
      @code = code.freeze
      @map = map&.freeze
      @entry = entry
      @dynamic_entry = dynamic_entry
      @imports = imports.freeze
      @dynamic_imports = dynamic_imports.freeze
      @exports = exports.freeze
      @module_ids = module_ids.freeze

      freeze
    end

    #: () -> bool
    def entry?
      @entry
    end

    #: () -> bool
    def dynamic_entry?
      @dynamic_entry
    end

    #: () -> String
    def to_s
      code
    end

    #: () -> String
    def inspect
      parts = [filename.inspect, "#{code.bytesize} bytes"]
      parts << "entry" if entry?
      parts << "map" if map

      "#<#{self.class.name} #{parts.join(" ")}>"
    end
  end
end
