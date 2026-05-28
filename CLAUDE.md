# lex-neo4j

Legion Extension connecting LegionIO to Neo4j graph database via the HTTP Cypher transaction API. Provides runners for Cypher queries, nodes, relationships, indexes/constraints, transactions, administration, and Graph Data Science (GDS) algorithms.

## Architecture

```
Legion::Extensions::Neo4j
├── Runners/
│   ├── Cypher            # Raw query execution, single/multi-statement
│   ├── Nodes             # CRUD + merge, count, labels
│   ├── Relationships     # CRUD + merge, neighbors, shortest path, types
│   ├── Indexes           # Indexes and constraints (uniqueness, existence, fulltext)
│   ├── Transactions      # Explicit transaction lifecycle (begin/execute/commit/rollback)
│   ├── Admin             # Server info, databases, procedures, functions, APOC stats
│   └── GraphDataScience  # GDS graph projections, PageRank, Louvain, node similarity
├── Helpers/Client        # Faraday connection (Basic auth)
├── Errors                # ReadOnlyError, CypherError
└── Client                # Standalone client class
```

## Key Design Decisions

- Uses Neo4j HTTP Cypher Transaction API (`/db/{database}/tx/commit` for auto-commit, `/db/{database}/tx` for explicit transactions)
- Basic auth with `Authorization: Basic base64(user:pass)` header
- Default database is `neo4j` (configurable)
- Default URL is `http://localhost:7474` (configurable)
- `CypherError` raised when Neo4j returns errors in the response body
- **Read-Only Guard**: write operations raise `ReadOnlyError` when `read_only: true`
- Node/relationship IDs use Neo4j 5.x `elementId()` (string format like `4:uuid:offset`)
- GDS runner assumes the Graph Data Science plugin is installed
- Admin operations against `system` database where required (e.g., SHOW DATABASES, CREATE DATABASE)
- Depends on `faraday` (>= 2.0)
