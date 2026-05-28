# frozen_string_literal: true

require 'legion/extensions/neo4j/helpers/client'

module Legion
  module Extensions
    module Neo4j
      module Runners
        module Admin
          include Legion::Extensions::Neo4j::Helpers::Client

          def server_info(url: nil, username: nil, password: nil, **)
            resp = connection(url: url, username: username, password: password).get('/')
            resp.body
          end

          def discovery(url: nil, username: nil, password: nil, **)
            resp = connection(url: url, username: username, password: password).get('/db/data/')
            resp.body
          end

          def list_databases(url: nil, username: nil, password: nil, **)
            execute_cypher('SHOW DATABASES', parameters: {}, database: 'system',
                                            url: url, username: username, password: password)
          end

          def database_info(name: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('SHOW DATABASE $name', parameters: { name: name }, database: 'system',
                                                  url: url, username: username, password: password)
          end

          def create_database(name:, url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher("CREATE DATABASE #{name}", parameters: {}, database: 'system',
                                                     url: url, username: username, password: password)
          end

          def drop_database(name:, url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher("DROP DATABASE #{name} IF EXISTS", parameters: {}, database: 'system',
                                                             url: url, username: username, password: password)
          end

          def list_procedures(database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('SHOW PROCEDURES', parameters: {}, database: database,
                                             url: url, username: username, password: password)
          end

          def list_functions(database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('SHOW FUNCTIONS', parameters: {}, database: database,
                                            url: url, username: username, password: password)
          end

          def call_procedure(name:, args: [], database: 'neo4j', url: nil, username: nil, password: nil, **)
            arg_placeholders = args.each_index.map { |i| "$arg#{i}" }.join(', ')
            params = args.each_with_index.to_h { |v, i| ["arg#{i}", v] }
            cypher = "CALL #{name}(#{arg_placeholders})"
            execute_cypher(cypher, parameters: params, database: database,
                                  url: url, username: username, password: password)
          end

          def db_stats(database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher(
              'CALL apoc.meta.stats() YIELD labels, relTypes, nodeCount, relCount ' \
              'RETURN labels, relTypes, nodeCount, relCount',
              parameters: {}, database: database,
              url: url, username: username, password: password
            )
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
