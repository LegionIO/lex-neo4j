# frozen_string_literal: true

require 'legion/extensions/neo4j/helpers/client'

module Legion
  module Extensions
    module Neo4j
      module Runners
        module Transactions
          include Legion::Extensions::Neo4j::Helpers::Client

          def begin_transaction(database: 'neo4j', url: nil, username: nil, password: nil, **)
            resp = connection(url: url, username: username, password: password)
                   .post("/db/#{database}/tx", { statements: [] })
            location = resp.headers&.[]('location')
            { body: resp.body, location: location }
          end

          def execute_in_transaction(transaction_url:, statements:, url: nil, username: nil, password: nil, **)
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
                   .post(transaction_url, payload)
            body = resp.body
            raise CypherError, body[:errors].map { |e| e['message'] }.join('; ') if body.is_a?(Hash) && body[:errors] && !body[:errors].empty?

            body
          end

          def commit_transaction(transaction_url:, url: nil, username: nil, password: nil, **)
            resp = connection(url: url, username: username, password: password)
                   .post("#{transaction_url}/commit", { statements: [] })
            body = resp.body
            raise CypherError, body[:errors].map { |e| e['message'] }.join('; ') if body.is_a?(Hash) && body[:errors] && !body[:errors].empty?

            body
          end

          def rollback_transaction(transaction_url:, url: nil, username: nil, password: nil, **)
            connection(url: url, username: username, password: password).delete(transaction_url)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
