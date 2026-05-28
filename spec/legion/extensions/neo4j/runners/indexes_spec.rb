# frozen_string_literal: true

require 'spec_helper'
require 'faraday'

RSpec.describe Legion::Extensions::Neo4j::Runners::Indexes do
  let(:runner_class) do
    Class.new do
      include Legion::Extensions::Neo4j::Runners::Indexes
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

  describe '#list_indexes' do
    it 'executes SHOW INDEXES' do
      runner.list_indexes
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to eq('SHOW INDEXES')
      end
    end
  end

  describe '#create_index' do
    it 'creates an index on a label and property' do
      runner.create_index(label: 'Person', properties: 'name')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('CREATE INDEX')
        expect(stmt).to include('FOR (n:Person)')
        expect(stmt).to include('n.name')
      end
    end

    it 'supports named indexes' do
      runner.create_index(label: 'Person', properties: 'name', name: 'idx_person_name')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('idx_person_name')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.create_index(label: 'X', properties: 'y', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#drop_index' do
    it 'drops by name with IF EXISTS' do
      runner.drop_index(name: 'my_index')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to eq('DROP INDEX my_index IF EXISTS')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.drop_index(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#list_constraints' do
    it 'executes SHOW CONSTRAINTS' do
      runner.list_constraints
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to eq('SHOW CONSTRAINTS')
      end
    end
  end

  describe '#create_uniqueness_constraint' do
    it 'creates a uniqueness constraint' do
      runner.create_uniqueness_constraint(label: 'Person', property: 'email')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('FOR (n:Person) REQUIRE n.email IS UNIQUE')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.create_uniqueness_constraint(label: 'X', property: 'y', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#create_existence_constraint' do
    it 'creates an existence constraint' do
      runner.create_existence_constraint(label: 'Person', property: 'name')
      expect(fake_conn).to have_received(:post) do |_path, payload|
        stmt = payload[:statements].first[:statement]
        expect(stmt).to include('FOR (n:Person) REQUIRE n.name IS NOT NULL')
      end
    end

    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.create_existence_constraint(label: 'X', property: 'y', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end

  describe '#drop_constraint' do
    it 'raises ReadOnlyError when read_only is true' do
      expect { runner.drop_constraint(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Neo4j::ReadOnlyError)
    end
  end
end
