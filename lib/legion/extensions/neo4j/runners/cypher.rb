# frozen_string_literal: true

require 'legion/extensions/neo4j/helpers/client'

module Legion
  module Extensions
    module Neo4j
      module Runners
        module Cypher
          include Legion::Extensions::Neo4j::Helpers::Client

          def query(statement, parameters: {}, database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher(statement, parameters: parameters, database: database,
                                     url: url, username: username, password: password)
          end

          def query_single(statement, parameters: {}, database: 'neo4j', url: nil, username: nil, password: nil, **)
            result = execute_cypher(statement, parameters: parameters, database: database,
                                              url: url, username: username, password: password)
            results = result.dig('results', 0, 'data')
            return nil if results.nil? || results.empty?

            results.first
          end

          def multi_statement(statements, database: 'neo4j', url: nil, username: nil, password: nil, **)
            payload = {
              statements: statements.map do |s|
                if s.is_a?(String)
                  { statement: s, parameters: {} }
                else
                  { statement: s[:statement], parameters: s[:parameters] || {} }
                end
              end
            }
            resp = connection(url: url, username: username, password: password)
                   .post("/db/#{database}/tx/commit", payload)
            body = resp.body
            raise CypherError, body[:errors].map { |e| e['message'] }.join('; ') if body.is_a?(Hash) && body[:errors] && !body[:errors].empty?

            body
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
