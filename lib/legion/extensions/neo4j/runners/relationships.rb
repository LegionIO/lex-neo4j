# frozen_string_literal: true

require 'legion/extensions/neo4j/helpers/client'

module Legion
  module Extensions
    module Neo4j
      module Runners
        module Relationships
          include Legion::Extensions::Neo4j::Helpers::Client

          def find_relationships(type:, properties: {}, limit: 25, database: 'neo4j',
                                 url: nil, username: nil, password: nil, **)
            where_clause = properties.keys.map { |k| "r.#{k} = $#{k}" }.join(' AND ')
            cypher = "MATCH (a)-[r:#{type}]->(b)"
            cypher += " WHERE #{where_clause}" unless where_clause.empty?
            cypher += ' RETURN a, r, b LIMIT $limit'
            execute_cypher(cypher, parameters: properties.merge(limit: limit),
                                  database: database, url: url, username: username, password: password)
          end

          def get_relationship(id:, database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('MATCH (a)-[r]->(b) WHERE elementId(r) = $id RETURN a, r, b',
                          parameters: { id: id }, database: database,
                          url: url, username: username, password: password)
          end

          def create_relationship(from_id:, to_id:, type:, properties: {}, database: 'neo4j',
                                  url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            cypher = 'MATCH (a), (b) WHERE elementId(a) = $from_id AND elementId(b) = $to_id ' \
                     "CREATE (a)-[r:#{type} $props]->(b) RETURN a, r, b"
            execute_cypher(cypher,
                          parameters: { from_id: from_id, to_id: to_id, props: properties },
                          database: database, url: url, username: username, password: password)
          end

          def update_relationship(id:, properties: {}, database: 'neo4j', url: nil, username: nil, password: nil,
                                  read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher('MATCH ()-[r]->() WHERE elementId(r) = $id SET r += $props RETURN r',
                          parameters: { id: id, props: properties }, database: database,
                          url: url, username: username, password: password)
          end

          def delete_relationship(id:, database: 'neo4j', url: nil, username: nil, password: nil,
                                  read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher('MATCH ()-[r]->() WHERE elementId(r) = $id DELETE r',
                          parameters: { id: id }, database: database,
                          url: url, username: username, password: password)
          end

          def merge_relationship(from_id:, to_id:, type:, on_create: {}, on_match: {}, database: 'neo4j',
                                 url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            cypher = 'MATCH (a), (b) WHERE elementId(a) = $from_id AND elementId(b) = $to_id ' \
                     "MERGE (a)-[r:#{type}]->(b)"
            cypher += ' ON CREATE SET r += $on_create' unless on_create.empty?
            cypher += ' ON MATCH SET r += $on_match' unless on_match.empty?
            cypher += ' RETURN a, r, b'
            execute_cypher(cypher,
                          parameters: { from_id: from_id, to_id: to_id, on_create: on_create, on_match: on_match },
                          database: database, url: url, username: username, password: password)
          end

          def list_relationship_types(database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('CALL db.relationshipTypes() YIELD relationshipType RETURN relationshipType',
                          parameters: {}, database: database,
                          url: url, username: username, password: password)
          end

          def neighbors(id:, direction: :both, type: nil, limit: 25, database: 'neo4j',
                        url: nil, username: nil, password: nil, **)
            rel = type ? ":#{type}" : ''
            pattern = case direction
                      when :outgoing then "(a)-[r#{rel}]->(b)"
                      when :incoming then "(a)<-[r#{rel}]-(b)"
                      else "(a)-[r#{rel}]-(b)"
                      end
            cypher = "MATCH #{pattern} WHERE elementId(a) = $id RETURN b, r LIMIT $limit"
            execute_cypher(cypher, parameters: { id: id, limit: limit },
                                  database: database, url: url, username: username, password: password)
          end

          def shortest_path(from_id:, to_id:, max_depth: 15, database: 'neo4j',
                            url: nil, username: nil, password: nil, **)
            cypher = 'MATCH (a), (b) WHERE elementId(a) = $from_id AND elementId(b) = $to_id ' \
                     "MATCH p = shortestPath((a)-[*..#{max_depth}]-(b)) RETURN p"
            execute_cypher(cypher, parameters: { from_id: from_id, to_id: to_id },
                                  database: database, url: url, username: username, password: password)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
