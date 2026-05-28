# frozen_string_literal: true

require 'spec_helper'
require 'faraday'

RSpec.describe Legion::Extensions::Neo4j::Runners::Relationships do
  let(:runner_class) do
    Class.new do
      include Legion::Extensions::Neo4j::Runners::Relationships
    end
  end

  let(:runner) { runner_class.new }

  let(:success_body) { { 'results' => [{ 'columns' => %w[a r b], 'data' => [] }], 'errors' => [] } }

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

  describe '#find_relationships' do
    it 'queries by relationship type' do
      runner.find_relationships(type: 'KNOWS')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('MATCH (a)-[r:KNOWS]->(b)')
      end
    end
  end

  describe '#get_relationship' do
    it 'queries by elementId' do
      runner.get_relationship(id: '5:abc:456')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('elementId(r) = $id')
      end
    end
  end

  describe '#create_relationship' do
    it 'creates relationship between two nodes' do
      runner.create_relationship(from_id: '4:a:1', to_id: '4:b:2', type: 'KNOWS')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('CREATE (a)-[r:KNOWS $props]->(b)')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.create_relationship(from_id: 'a', to_id: 'b', type: 'X', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#update_relationship' do
    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.update_relationship(id: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#delete_relationship' do
    it 'deletes by elementId' do
      runner.delete_relationship(id: '5:abc:456')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('DELETE r')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.delete_relationship(id: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#neighbors' do
    it 'finds outgoing neighbors' do
      runner.neighbors(id: '4:a:1', direction: :outgoing)
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('(a)-[r]->(b)')
      end
    end

    it 'finds incoming neighbors' do
      runner.neighbors(id: '4:a:1', direction: :incoming)
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('(a)<-[r]-(b)')
      end
    end

    it 'finds both-direction neighbors by default' do
      runner.neighbors(id: '4:a:1')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('(a)-[r]-(b)')
      end
    end

    it 'filters by relationship type' do
      runner.neighbors(id: '4:a:1', type: 'KNOWS', direction: :outgoing)
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('(a)-[r:KNOWS]->(b)')
      end
    end
  end

  describe '#shortest_path' do
    it 'finds shortest path between two nodes' do
      runner.shortest_path(from_id: '4:a:1', to_id: '4:b:2')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('shortestPath')
      end
    end
  end

  describe '#list_relationship_types' do
    it 'calls db.relationshipTypes()' do
      runner.list_relationship_types
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('db.relationshipTypes()')
      end
    end
  end
end
