# lex-neo4j

Legion Extension for [Neo4j](https://neo4j.com/) graph database via the HTTP Cypher transaction API.

## Installation

```ruby
gem 'lex-neo4j'
```

## Usage

```ruby
client = Legion::Extensions::Neo4j::Client.new(
  url: 'http://localhost:7474',
  username: 'neo4j',
  password: 'your-password',
  database: 'neo4j'
)

# Raw Cypher
client.query('MATCH (n:Person) RETURN n LIMIT 10')
client.query('CREATE (n:Person {name: $name}) RETURN n', parameters: { name: 'Alice' })

# Nodes
client.find_nodes(label: 'Person', properties: { name: 'Alice' })
client.create_node(label: 'Person', properties: { name: 'Bob', age: 30 })
client.merge_node(label: 'Person', match_properties: { email: 'bob@example.com' }, on_create: { created_at: Time.now.to_s })
client.count_nodes(label: 'Person')
client.list_labels

# Relationships
client.create_relationship(from_id: node1_id, to_id: node2_id, type: 'KNOWS', properties: { since: 2020 })
client.neighbors(id: node_id, direction: :outgoing, type: 'KNOWS')
client.shortest_path(from_id: node1_id, to_id: node2_id)
client.list_relationship_types

# Indexes & Constraints
client.list_indexes
client.create_index(label: 'Person', properties: ['name', 'email'], name: 'idx_person_name_email')
client.create_uniqueness_constraint(label: 'Person', property: 'email', name: 'uniq_person_email')
client.create_existence_constraint(label: 'Person', property: 'name')

# Explicit Transactions
tx = client.begin_transaction
client.execute_in_transaction(transaction_url: tx[:location], statements: ['CREATE (n:Temp) RETURN n'])
client.commit_transaction(transaction_url: tx[:location])

# Administration
client.server_info
client.list_databases
client.list_procedures
client.call_procedure(name: 'dbms.components')

# Graph Data Science (requires GDS plugin)
client.project_graph(name: 'social', node_projection: 'Person', relationship_projection: 'KNOWS')
client.run_pagerank(graph_name: 'social')
client.run_louvain(graph_name: 'social')
client.run_node_similarity(graph_name: 'social')
client.drop_graph(name: 'social')
```

### Read-Only Mode

```ruby
client = Legion::Extensions::Neo4j::Client.new(
  url: 'http://localhost:7474',
  username: 'neo4j',
  password: 'pass',
  read_only: true
)

client.find_nodes(label: 'Person')  # works
client.create_node(label: 'Person') # raises ReadOnlyError
```

## Runners

| Runner | Purpose |
|--------|---------|
| Cypher | Raw query execution, multi-statement batches |
| Nodes | Node CRUD, merge, count, label listing |
| Relationships | Relationship CRUD, merge, traversal, shortest path |
| Indexes | Index and constraint management (range, fulltext, uniqueness, existence) |
| Transactions | Explicit transaction lifecycle |
| Admin | Server info, database management, procedures, functions |
| GraphDataScience | GDS graph projections and algorithms (PageRank, Louvain, similarity) |

## License

MIT
