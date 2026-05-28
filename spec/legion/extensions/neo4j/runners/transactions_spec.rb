# frozen_string_literal: true

require 'spec_helper'
require 'faraday'

RSpec.describe Legion::Extensions::Neo4j::Runners::Transactions do
  let(:runner_class) do
    Class.new do
      include Legion::Extensions::Neo4j::Runners::Transactions
    end
  end

  let(:runner) { runner_class.new }

  let(:success_body) { { 'results' => [], 'errors' => [] } }

  let(:fake_response) do
    resp = double('FaradayResponse')
    allow(resp).to receive(:body).and_return(success_body)
    allow(resp).to receive(:headers).and_return({ 'location' => 'http://localhost:7474/db/neo4j/tx/1' })
    resp
  end

  let(:fake_conn) do
    conn = double('FaradayConnection')
    allow(conn).to receive(:post).and_return(fake_response)
    allow(conn).to receive(:delete).and_return(fake_response)
    conn
  end

  before do
    allow(runner).to receive(:connection).and_return(fake_conn)
  end

  describe '#begin_transaction' do
    it 'posts to /db/:database/tx' do
      runner.begin_transaction
      expect(fake_conn).to have_received(:post).with('/db/neo4j/tx', { statements: [] })
    end

    it 'returns body and location' do
      result = runner.begin_transaction
      expect(result[:location]).to eq('http://localhost:7474/db/neo4j/tx/1')
      expect(result[:body]).to eq(success_body)
    end
  end

  describe '#execute_in_transaction' do
    it 'posts statements to the transaction URL' do
      runner.execute_in_transaction(transaction_url: '/db/neo4j/tx/1', statements: ['RETURN 1'])
      expect(fake_conn).to have_received(:post).with('/db/neo4j/tx/1', anything)
    end

    context 'when errors returned' do
      let(:success_body) { { 'results' => [], 'errors' => [{ 'message' => 'oops' }] } }

      it 'raises CypherError' do
        expect { runner.execute_in_transaction(transaction_url: '/db/neo4j/tx/1', statements: ['BAD']) }
          .to raise_error(Legion::Extensions::Neo4j::CypherError, 'oops')
      end
    end
  end

  describe '#commit_transaction' do
    it 'posts to transaction_url/commit' do
      runner.commit_transaction(transaction_url: '/db/neo4j/tx/1')
      expect(fake_conn).to have_received(:post).with('/db/neo4j/tx/1/commit', { statements: [] })
    end
  end

  describe '#rollback_transaction' do
    it 'sends DELETE to transaction URL' do
      runner.rollback_transaction(transaction_url: '/db/neo4j/tx/1')
      expect(fake_conn).to have_received(:delete).with('/db/neo4j/tx/1')
    end
  end
end
