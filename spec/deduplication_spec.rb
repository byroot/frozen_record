require 'spec_helper'

describe 'deduplication' do

  it 'deduplicate string values' do
    pending("Strings can't be deduplicated before Ruby 2.5") if RUBY_VERSION < '2.5'

    records = [
      { 'name' => 'George'.dup },
    ]

    expect(records[0]['name']).to_not equal 'George'.freeze
    FrozenRecord::Deduplication.deep_deduplicate!(records)
    expect(records[0]['name']).to equal 'George'.freeze
  end

  it 'handles duplicated references' do
    # This simulates the YAML anchor behavior
    tags = { 'foo' => 'bar' }
    records = [
      { 'name' => 'George', 'tags' => tags },
      { 'name' => 'Peter', 'tags' => tags },
    ]

    expect(records[0]['tags']).to_not be_frozen
    FrozenRecord::Deduplication.deep_deduplicate!(records)
    expect(records[0]['tags']).to be_frozen
    expect(records[0]['tags']).to equal records[1]['tags']
  end

end