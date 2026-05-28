# frozen_string_literal: true

require 'legion/extensions/neo4j/version'
require 'legion/extensions/neo4j/errors'
require 'legion/extensions/neo4j/helpers/client'
require 'legion/extensions/neo4j/runners/cypher'
require 'legion/extensions/neo4j/runners/nodes'
require 'legion/extensions/neo4j/runners/relationships'
require 'legion/extensions/neo4j/runners/indexes'
require 'legion/extensions/neo4j/runners/transactions'
require 'legion/extensions/neo4j/runners/admin'
require 'legion/extensions/neo4j/runners/graph_data_science'
require 'legion/extensions/neo4j/client'

module Legion
  module Extensions
    module Neo4j
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false
    end
  end
end
