# frozen_string_literal: true

require 'legion/extensions/neo4j/helpers/client'

module Legion
  module Extensions
    module Neo4j
      module Runners
        module Indexes
          include Legion::Extensions::Neo4j::Helpers::Client

          def list_indexes(database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('SHOW INDEXES', parameters: {}, database: database,
                                          url: url, username: username, password: password)
          end

          def create_index(label:, properties:, name: nil, database: 'neo4j', url: nil, username: nil, password: nil,
                           read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            props = Array(properties).map { |p| "n.#{p}" }.join(', ')
            cypher = 'CREATE INDEX'
            cypher += " #{name}" if name
            cypher += " FOR (n:#{label}) ON (#{props})"
            execute_cypher(cypher, parameters: {}, database: database,
                                  url: url, username: username, password: password)
          end

          def create_fulltext_index(name:, labels:, properties:, database: 'neo4j', url: nil, username: nil,
                                    password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            label_list = Array(labels).map { |l| "'#{l}'" }.join(', ')
            prop_list = Array(properties).map { |p| "'#{p}'" }.join(', ')
            cypher = "CREATE FULLTEXT INDEX #{name} FOR (n:#{label_list}) ON EACH [#{prop_list}]"
            execute_cypher(cypher, parameters: {}, database: database,
                                  url: url, username: username, password: password)
          end

          def drop_index(name:, database: 'neo4j', url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher("DROP INDEX #{name} IF EXISTS", parameters: {}, database: database,
                                                          url: url, username: username, password: password)
          end

          def list_constraints(database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('SHOW CONSTRAINTS', parameters: {}, database: database,
                                              url: url, username: username, password: password)
          end

          def create_uniqueness_constraint(label:, property:, name: nil, database: 'neo4j', url: nil, username: nil,
                                           password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            cypher = 'CREATE CONSTRAINT'
            cypher += " #{name}" if name
            cypher += " FOR (n:#{label}) REQUIRE n.#{property} IS UNIQUE"
            execute_cypher(cypher, parameters: {}, database: database,
                                  url: url, username: username, password: password)
          end

          def create_existence_constraint(label:, property:, name: nil, database: 'neo4j', url: nil, username: nil,
                                          password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            cypher = 'CREATE CONSTRAINT'
            cypher += " #{name}" if name
            cypher += " FOR (n:#{label}) REQUIRE n.#{property} IS NOT NULL"
            execute_cypher(cypher, parameters: {}, database: database,
                                  url: url, username: username, password: password)
          end

          def drop_constraint(name:, database: 'neo4j', url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher("DROP CONSTRAINT #{name} IF EXISTS", parameters: {}, database: database,
                                                               url: url, username: username, password: password)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
