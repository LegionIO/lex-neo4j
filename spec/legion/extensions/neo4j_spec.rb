# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Neo4j do
  it 'has a version number' do
    expect(Legion::Extensions::Neo4j::VERSION).not_to be_nil
  end

  it 'defines ReadOnlyError' do
    expect(Legion::Extensions::Neo4j::ReadOnlyError).to be < StandardError
  end

  it 'defines CypherError' do
    expect(Legion::Extensions::Neo4j::CypherError).to be < StandardError
  end
end
