# frozen_string_literal: true

require 'legion/extensions/neo4j/helpers/client'
require 'legion/extensions/neo4j/runners/cypher'
require 'legion/extensions/neo4j/runners/nodes'
require 'legion/extensions/neo4j/runners/relationships'
require 'legion/extensions/neo4j/runners/indexes'
require 'legion/extensions/neo4j/runners/transactions'
require 'legion/extensions/neo4j/runners/admin'
require 'legion/extensions/neo4j/runners/graph_data_science'

module Legion
  module Extensions
    module Neo4j
      class Client
        include Helpers::Client
        include Runners::Cypher
        include Runners::Nodes
        include Runners::Relationships
        include Runners::Indexes
        include Runners::Transactions
        include Runners::Admin
        include Runners::GraphDataScience

        attr_reader :opts

        def initialize(url: 'http://localhost:7474', username: 'neo4j', password: nil, database: 'neo4j',
                       read_only: false, **extra)
          @opts = { url: url, username: username, password: password, database: database,
                    read_only: read_only, **extra }
        end

        def connection(**override)
          super(**@opts.merge(override.compact))
        end

        def execute_cypher(query, parameters: {}, database: nil, **override)
          db = database || @opts[:database]
          super(query, parameters: parameters, database: db, **@opts.merge(override.compact))
        end
      end
    end
  end
end
