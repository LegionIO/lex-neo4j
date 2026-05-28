# frozen_string_literal: true

module Legion
  module Extensions
    module Neo4j
      class ReadOnlyError < StandardError; end
      class CypherError < StandardError; end
    end
  end
end
