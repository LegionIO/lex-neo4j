# frozen_string_literal: true

require 'spec_helper'
require 'faraday'

RSpec.describe Legion::Extensions::Neo4j::Runners::GraphDataScience do
  let(:runner_class) do
    Class.new do
      include Legion::Extensions::Neo4j::Runners::GraphDataScience
    end
  end

  let(:runner) { runner_class.new }

  let(:success_body) { { 'results' => [{ 'columns' => [], 'data' => [] }], 'errors' => [] } }

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

  describe '#list_graphs' do
    it 'calls gds.graph.list()' do
      runner.list_graphs
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('gds.graph.list()')
      end
    end
  end

  describe '#project_graph' do
    it 'projects a named graph' do
      runner.project_graph(name: 'myGraph', node_projection: 'Person', relationship_projection: 'KNOWS')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('gds.graph.project')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.project_graph(name: 'x', node_projection: 'A', relationship_projection: 'B', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#drop_graph' do
    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.drop_graph(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#run_pagerank' do
    it 'streams pagerank results by default' do
      runner.run_pagerank(graph_name: 'myGraph')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('gds.pageRank.stream')
      end
    end

    it 'writes pagerank when write_property given' do
      runner.run_pagerank(graph_name: 'myGraph', write_property: 'pr')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('gds.pageRank.write')
      end
    end

    it 'raises ReadOnlyError when write_property given with read_only' do
      expect { runner.run_pagerank(graph_name: 'x', write_property: 'pr', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#run_louvain' do
    it 'streams louvain results by default' do
      runner.run_louvain(graph_name: 'myGraph')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('gds.louvain.stream')
      end
    end

    it 'raises ReadOnlyError when write_property given with read_only' do
      expect { runner.run_louvain(graph_name: 'x', write_property: 'c', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#run_node_similarity' do
    it 'streams similarity results' do
      runner.run_node_similarity(graph_name: 'myGraph')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('gds.nodeSimilarity.stream')
      end
    end
  end
end
