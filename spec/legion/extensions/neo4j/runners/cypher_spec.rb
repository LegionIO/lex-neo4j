# frozen_string_literal: true

require 'spec_helper'
require 'faraday'

RSpec.describe Legion::Extensions::Neo4j::Runners::Cypher do
  let(:runner_class) do
    Class.new do
      include Legion::Extensions::Neo4j::Runners::Cypher
    end
  end

  let(:runner) { runner_class.new }

  let(:success_body) { { 'results' => [{ 'columns' => ['n'], 'data' => [{ 'row' => [{}] }] }], 'errors' => [] } }

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

  describe '#query' do
    it 'posts to /db/:database/tx/commit' do
      runner.query('MATCH (n) RETURN n LIMIT 10')
      expect(fake_conn).to have_received(:post).with('/db/neo4j/tx/commit', anything)
    end

    it 'wraps statement in statements array' do
      runner.query('RETURN 1', parameters: { x: 1 })
      expect(fake_conn).to have_received(:post).with(anything,
                                                     hash_including(statements: [{ statement: 'RETURN 1', parameters: { x: 1 } }]))
    end

    it 'returns the response body' do
      result = runner.query('RETURN 1')
      expect(result).to eq(success_body)
    end
  end

  describe '#query_single' do
    it 'returns the first data row' do
      result = runner.query_single('RETURN 1')
      expect(result).to eq({ 'row' => [{}] })
    end

    context 'when no results' do
      let(:success_body) { { 'results' => [{ 'columns' => [], 'data' => [] }], 'errors' => [] } }

      it 'returns nil' do
        result = runner.query_single('MATCH (n:Missing) RETURN n')
        expect(result).to be_nil
      end
    end
  end

  describe '#multi_statement' do
    it 'sends multiple statements' do
      runner.multi_statement(['RETURN 1', { statement: 'RETURN 2', parameters: {} }])
      expect(fake_conn).to have_received(:post).with(anything,
                                                     hash_including(statements: [
                                                                     { statement: 'RETURN 1', parameters: {} },
                                                                     { statement: 'RETURN 2', parameters: {} }
                                                                   ]))
    end
  end

  context 'when cypher errors are returned' do
    let(:success_body) { { 'results' => [], 'errors' => [{ 'message' => 'SyntaxError' }] } }

    it 'raises CypherError' do
      expect { runner.query('INVALID CYPHER') }
        .to raise_error(Legion::Extensions::Neo4j::CypherError, 'SyntaxError')
    end
  end
end
