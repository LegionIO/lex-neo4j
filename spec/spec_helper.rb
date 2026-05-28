# frozen_string_literal: true

require 'bundler/setup'

require 'legion/json'
require 'legion/logging'
require 'legion/settings'
require 'legion/cache'
require 'legion/crypt'
require 'legion/data'
require 'legion/transport'

module Legion
  module Extensions
    module Helpers
      module Lex
        def self.included(base)
          base.extend base if base.instance_of?(Module)
        end
      end
    end
  end
end

require 'legion/extensions/neo4j'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
