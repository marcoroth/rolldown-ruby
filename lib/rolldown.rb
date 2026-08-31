# frozen_string_literal: true

require_relative "rolldown/version"
require_relative "rolldown/backend"

begin
  require "rolldown/rolldown"
rescue LoadError
  require_relative "rolldown/errors"
end

module Rolldown
  #: () -> String
  def self.rolldown_version
    Backend.rolldown_version
  end
end
