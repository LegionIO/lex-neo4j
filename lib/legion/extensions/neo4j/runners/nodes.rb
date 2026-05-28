# frozen_string_literal: true

require 'legion/extensions/neo4j/helpers/client'

module Legion
  module Extensions
    module Neo4j
      module Runners
        module Nodes
          include Legion::Extensions::Neo4j::Helpers::Client

          def find_nodes(label:, properties: {}, limit: 25, database: 'neo4j', url: nil, username: nil, password: nil, **)
            where_clause = properties.keys.map { |k| "n.#{k} = $#{k}" }.join(' AND ')
            cypher = "MATCH (n:#{label})"
            cypher += " WHERE #{where_clause}" unless where_clause.empty?
            cypher += ' RETURN n LIMIT $limit'
            execute_cypher(cypher, parameters: properties.merge(limit: limit),
                                  database: database, url: url, username: username, password: password)
          end

          def get_node(id:, database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('MATCH (n) WHERE elementId(n) = $id RETURN n',
                           parameters: { id: id }, database: database,
                           url: url, username: username, password: password)
          end

          def create_node(label:, properties: {}, database: 'neo4j', url: nil, username: nil, password: nil,
                          read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher("CREATE (n:#{label} $props) RETURN n",
                           parameters: { props: properties }, database: database,
                           url: url, username: username, password: password)
          end

          def update_node(id:, properties: {}, database: 'neo4j', url: nil, username: nil, password: nil,
                          read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher('MATCH (n) WHERE elementId(n) = $id SET n += $props RETURN n',
                           parameters: { id: id, props: properties }, database: database,
                           url: url, username: username, password: password)
          end

          def delete_node(id:, detach: false, database: 'neo4j', url: nil, username: nil, password: nil,
                          read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            delete_keyword = detach ? 'DETACH DELETE' : 'DELETE'
            execute_cypher("MATCH (n) WHERE elementId(n) = $id #{delete_keyword} n",
                           parameters: { id: id }, database: database,
                           url: url, username: username, password: password)
          end

          def merge_node(label:, match_properties: {}, on_create: {}, on_match: {}, database: 'neo4j',
                         url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            cypher = "MERGE (n:#{label} $match_props)"
            cypher += ' ON CREATE SET n += $on_create' unless on_create.empty?
            cypher += ' ON MATCH SET n += $on_match' unless on_match.empty?
            cypher += ' RETURN n'
            execute_cypher(cypher,
                           parameters: { match_props: match_properties, on_create: on_create, on_match: on_match },
                           database: database, url: url, username: username, password: password)
          end

          def count_nodes(label: nil, database: 'neo4j', url: nil, username: nil, password: nil, **)
            cypher = label ? "MATCH (n:#{label}) RETURN count(n) AS count" : 'MATCH (n) RETURN count(n) AS count'
            execute_cypher(cypher, parameters: {}, database: database,
                                  url: url, username: username, password: password)
          end

          def list_labels(database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('CALL db.labels() YIELD label RETURN label',
                           parameters: {}, database: database,
                           url: url, username: username, password: password)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
