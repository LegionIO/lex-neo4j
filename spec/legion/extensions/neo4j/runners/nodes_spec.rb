# frozen_string_literal: true

require 'spec_helper'
require 'faraday'

RSpec.describe Legion::Extensions::Neo4j::Runners::Nodes do
  let(:runner_class) do
    Class.new do
      include Legion::Extensions::Neo4j::Runners::Nodes
    end
  end

  let(:runner) { runner_class.new }

  let(:success_body) { { 'results' => [{ 'columns' => ['n'], 'data' => [] }], 'errors' => [] } }

  let(:fake_response) do
    resp = double('FaradayResponse')
    allow(resp).to receive(:body).and_return(success_body)
    resp
  end

  let(:fake_conn) do
    conn = double('FaradayConnection')
    allow(conn).to receive(:post).and_return(fake_response)
    conn
  end

  before do
    allow(runner).to receive(:connection).and_return(fake_conn)
  end

  describe '#find_nodes' do
    it 'executes a MATCH query with label' do
      runner.find_nodes(label: 'Person')
      expect(fake_conn).to have_received(:post).with('/db/neo4j/tx/commit', anything) do |_path, payload|
        expect(payload[:statements].first[:statement]).to include('MATCH (n:Person)')
      end
    end

    it 'includes WHERE clause when properties given' do
      runner.find_nodes(label: 'Person', properties: { name: 'Alice' })
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('WHERE')
        expect(stmt).to include('n.name = $name')
      end
    end
  end

  describe '#get_node' do
    it 'queries by elementId' do
      runner.get_node(id: '4:abc:123')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('elementId(n) = $id')
      end
    end
  end

  describe '#create_node' do
    it 'executes CREATE with label and properties' do
      runner.create_node(label: 'Person', properties: { name: 'Bob' })
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('CREATE (n:Person $props)')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.create_node(label: 'Person', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#update_node' do
    it 'executes SET with properties' do
      runner.update_node(id: '4:abc:123', properties: { age: 30 })
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('SET n += $props')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.update_node(id: '4:abc:123', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#delete_node' do
    it 'executes DELETE' do
      runner.delete_node(id: '4:abc:123')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('DELETE n')
        expect(stmt).not_to include('DETACH')
      end
    end

    it 'executes DETACH DELETE when detach: true' do
      runner.delete_node(id: '4:abc:123', detach: true)
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('DETACH DELETE n')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.delete_node(id: '4:abc:123', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#merge_node' do
    it 'executes MERGE' do
      runner.merge_node(label: 'Person', match_properties: { name: 'Alice' }, on_create: { created: true })
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('MERGE (n:Person $match_props)')
        expect(stmt).to include('ON CREATE SET')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.merge_node(label: 'Person', match_properties: {}, read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#count_nodes' do
    it 'counts all nodes when no label given' do
      runner.count_nodes
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('MATCH (n) RETURN count(n)')
      end
    end

    it 'counts nodes with label' do
      runner.count_nodes(label: 'Person')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('MATCH (n:Person)')
      end
    end
  end

  describe '#list_labels' do
    it 'calls db.labels()' do
      runner.list_labels
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('db.labels()')
      end
    end
  end
end
