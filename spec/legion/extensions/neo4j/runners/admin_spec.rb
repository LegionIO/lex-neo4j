# frozen_string_literal: true

require 'spec_helper'
require 'faraday'

RSpec.describe Legion::Extensions::Neo4j::Runners::Admin do
  let(:runner_class) do
    Class.new do
      include Legion::Extensions::Neo4j::Runners::Admin
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
    allow(conn).to receive(:get).and_return(fake_response)
    allow(conn).to receive(:post).and_return(fake_response)
    conn
  end

  before do
    allow(runner).to receive(:connection).and_return(fake_conn)
  end

  describe '#server_info' do
    it 'GETs /' do
      runner.server_info
      expect(fake_conn).to have_received(:get).with('/')
    end
  end

  describe '#list_databases' do
    it 'executes SHOW DATABASES against system db' do
      runner.list_databases
      expect(fake_conn).to have_received(:post).with('/db/system/tx/commit', anything) do |_path, payload|
        expect(payload[:statements].first[:statement]).to eq('SHOW DATABASES')
      end
    end
  end

  describe '#create_database' do
    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.create_database(name: 'test', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end

    it 'executes CREATE DATABASE' do
      runner.create_database(name: 'mydb')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to eq('CREATE DATABASE mydb')
      end
    end
  end

  describe '#drop_database' do
    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.drop_database(name: 'test', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#list_procedures' do
    it 'executes SHOW PROCEDURES' do
      runner.list_procedures
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to eq('SHOW PROCEDURES')
      end
    end
  end

  describe '#list_functions' do
    it 'executes SHOW FUNCTIONS' do
      runner.list_functions
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to eq('SHOW FUNCTIONS')
      end
    end
  end

  describe '#call_procedure' do
    it 'calls a procedure with args' do
      runner.call_procedure(name: 'dbms.components', args: [])
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('CALL dbms.components(')
      end
    end
  end
end
