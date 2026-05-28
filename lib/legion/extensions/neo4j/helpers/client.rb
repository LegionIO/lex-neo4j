# frozen_string_literal: true

require 'faraday'
require 'base64'

module Legion
  module Extensions
    module Neo4j
      module Helpers
        module Client
          def connection(url: nil, username: nil, password: nil, database: 'neo4j', **_opts)
            Faraday.new(url: url) do |conn|
              conn.request :json
              conn.response :json, content_type: /\bjson$/
              if username && password
                conn.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{username}:#{password}")}"
              end
              conn.headers['Content-Type'] = 'application/json'
              conn.headers['Accept'] = 'application/json'
            end
          end

          def execute_cypher(query, parameters: {}, database: 'neo4j', url: nil, username: nil, password: nil, **)
            payload = { statements: [{ statement: query, parameters: parameters }] }
            resp = connection(url: url, username: username, password: password)
                   .post("/db/#{database}/tx/commit", payload)
            body = resp.body
            if body.is_a?(Hash) && body['errors'] && !body['errors'].empty?
              raise CypherError, body['errors'].map { |e| e['message'] }.join('; ')
            end

            body
          end
        end
      end
    end
  end
end
