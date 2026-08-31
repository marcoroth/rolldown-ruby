# frozen_string_literal: true

module Rolldown
  class Diagnostic
    attr_reader :kind #: String
    attr_reader :severity #: String
    attr_reader :message #: String
    attr_reader :file #: String?
    attr_reader :line #: Integer?
    attr_reader :column #: Integer?

    #: (Hash[String, untyped]) -> Rolldown::Diagnostic
    def self.from_hash(hash)
      new(
        kind: hash.fetch("kind"),
        severity: hash.fetch("severity"),
        message: hash.fetch("message"),
        file: hash["file"],
        line: hash["line"],
        column: hash["column"]
      )
    end

    #: (kind: String, severity: String, message: String, file: String?, line: Integer?, column: Integer?) -> void
    def initialize(kind:, severity:, message:, file:, line:, column:)
      @kind = kind.freeze
      @severity = severity.freeze
      @message = message.freeze
      @file = file&.freeze
      @line = line
      @column = column

      freeze
    end

    #: () -> bool
    def error?
      severity == "error"
    end

    #: () -> bool
    def warning?
      severity == "warning"
    end

    #: () -> String
    def to_s
      message
    end

    #: () -> String
    def inspect
      "#<#{self.class.name} #{severity} #{kind} #{message.inspect}>"
    end
  end
end
