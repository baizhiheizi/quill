# frozen_string_literal: true

module DesignSystem
  # A single lint finding emitted by DesignSystem::Lint.
  #
  # Attributes:
  #   rule_id  - "DS001".."DS013"
  #   severity - :error | :warning | :info
  #   file     - path relative to Rails.root
  #   line     - 1-indexed line number, or 0 if unknown
  #   message  - one-line explanation
  class Violation
    attr_reader :rule_id, :severity, :file, :line, :message

    def initialize(rule_id:, severity:, file:, line: 0, message:)
      @rule_id  = rule_id
      @severity = severity
      @file     = file
      @line     = line
      @message  = message
    end

    def to_h
      {
        rule_id: rule_id,
        severity: severity,
        file: file,
        line: line,
        message: message
      }
    end
  end
end
