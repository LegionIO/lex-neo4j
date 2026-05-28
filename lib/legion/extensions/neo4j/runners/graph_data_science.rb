# frozen_string_literal: true

require 'legion/extensions/neo4j/helpers/client'

module Legion
  module Extensions
    module Neo4j
      module Runners
        module GraphDataScience
          include Legion::Extensions::Neo4j::Helpers::Client

          def list_graphs(database: 'neo4j', url: nil, username: nil, password: nil, **)
            execute_cypher('CALL gds.graph.list() YIELD graphName, nodeCount, relationshipCount ' \
                           'RETURN graphName, nodeCount, relationshipCount',
                           parameters: {}, database: database,
                           url: url, username: username, password: password)
          end

          def project_graph(name:, node_projection:, relationship_projection:, database: 'neo4j',
                            url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher('CALL gds.graph.project($name, $nodes, $rels)',
                           parameters: { name: name, nodes: node_projection, rels: relationship_projection },
                           database: database, url: url, username: username, password: password)
          end

          def drop_graph(name:, database: 'neo4j', url: nil, username: nil, password: nil, read_only: false, **)
            raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

            execute_cypher('CALL gds.graph.drop($name)',
                           parameters: { name: name }, database: database,
                           url: url, username: username, password: password)
          end

          def run_pagerank(graph_name:, write_property: nil, database: 'neo4j', url: nil, username: nil,
                           password: nil, read_only: false, **)
            if write_property
              raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

              execute_cypher('CALL gds.pageRank.write($name, {writeProperty: $prop}) ' \
                             'YIELD nodePropertiesWritten, ranIterations',
                             parameters: { name: graph_name, prop: write_property },
                             database: database, url: url, username: username, password: password)
            else
              execute_cypher('CALL gds.pageRank.stream($name) YIELD nodeId, score ' \
                             'RETURN gds.util.asNode(nodeId).name AS name, score ' \
                             'ORDER BY score DESC LIMIT 25',
                             parameters: { name: graph_name },
                             database: database, url: url, username: username, password: password)
            end
          end

          def run_louvain(graph_name:, write_property: nil, database: 'neo4j', url: nil, username: nil,
                          password: nil, read_only: false, **)
            if write_property
              raise ReadOnlyError, 'Write operations disabled (read_only mode)' if read_only

              execute_cypher('CALL gds.louvain.write($name, {writeProperty: $prop}) ' \
                             'YIELD communityCount, modularity',
                             parameters: { name: graph_name, prop: write_property },
                             database: database, url: url, username: username, password: password)
            else
              execute_cypher('CALL gds.louvain.stream($name) YIELD nodeId, communityId ' \
                             'RETURN gds.util.asNode(nodeId).name AS name, communityId ' \
                             'ORDER BY communityId LIMIT 100',
                             parameters: { name: graph_name },
                             database: database, url: url, username: username, password: password)
            end
          end

          def run_node_similarity(graph_name:, limit: 25, database: 'neo4j', url: nil, username: nil,
                                  password: nil, **)
            execute_cypher('CALL gds.nodeSimilarity.stream($name) YIELD node1, node2, similarity ' \
                           'RETURN gds.util.asNode(node1).name AS from, ' \
                           'gds.util.asNode(node2).name AS to, similarity ' \
                           'ORDER BY similarity DESC LIMIT $limit',
                           parameters: { name: graph_name, limit: limit },
                           database: database, url: url, username: username, password: password)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
