# Changelog

## [0.1.0] - 2026-05-28

### Added
- Initial release
- Cypher runner (raw query, single result, multi-statement)
- Nodes runner (find, get, create, update, delete, merge, count, list labels)
- Relationships runner (find, get, create, update, delete, merge, neighbors, shortest path, list types)
- Indexes runner (list/create/drop indexes, list/create/drop constraints — uniqueness and existence)
- Transactions runner (begin, execute, commit, rollback)
- Admin runner (server info, discovery, databases, procedures, functions, APOC stats)
- Graph Data Science runner (project/drop graphs, PageRank, Louvain, node similarity)
- Standalone Client class with read_only guard and configurable database
- Basic auth (username/password) via Faraday
- CypherError raised on Neo4j query errors
