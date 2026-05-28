# frozen_string_literal: true

require 'spec_helper'
require 'faraday'

RSpec.describe Legion::Extensions::Neo4j::Client do
  let(:client) { described_class.new(url: 'http://localhost:7474', username: 'neo4j', password: 'secret') }

  let(:success_body) { { 'results' => [{ 'columns' => [], 'data' => [] }], 'errors' => [] } }

  let(:fake_response) do
    resp = double('FaradayResponse')
    allow(resp).to receive(:body).and_return(success_body)
    allow(resp).to receive(:headers).and_return({})
    resp
  end

  let(:fake_conn) do
    conn = double('FaradayConnection')
    allow(conn).to receive(:get).and_return(fake_response)
    allow(conn).to receive(:post).and_return(fake_response)
    allow(conn).to receive(:delete).and_return(fake_response)
    conn
  end

  before do
    allow(Faraday).to receive(:new).and_return(fake_conn)
  end

  it 'includes all runner modules' do
    expect(client).to respond_to(:query)
    expect(client).to respond_to(:find_nodes)
    expect(client).to respond_to(:find_relationships)
    expect(client).to respond_to(:list_indexes)
    expect(client).to respond_to(:begin_transaction)
    expect(client).to respond_to(:server_info)
    expect(client).to respond_to(:list_graphs)
  end

  it 'stores opts with defaults' do
    expect(client.opts).to include(url: 'http://localhost:7474', username: 'neo4j', database: 'neo4j')
  end

  it 'defaults read_only to false' do
    expect(client.opts[:read_only]).to be false
  end

  describe 'read_only mode' do
    let(:ro_client) { described_class.new(url: 'http://localhost:7474', password: 'x', read_only: true) }

    it 'stores read_only in opts' do
      expect(ro_client.opts[:read_only]).to be true
    end
  end
end
