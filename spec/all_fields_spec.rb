require 'spec_helper'

describe 'Declaring all stored fields' do
  before do
    class AllFieldsDocument
      include Mongoid::Document
      include Mongoid::CachedJson
      field :name
      field :secret

      def display_name
        name.upcase
      end

      json_fields :all, secret: { properties: :all }, display_name: {}
      field :added_later
    end
  end

  after do
    AllFieldsDocument.delete_all
    Object.send(:remove_const, :AllFieldsDocument)
  end

  it 'expands fields at declaration time and adds computed fields' do
    document = AllFieldsDocument.create!(name: 'example', secret: 'hidden', added_later: 'not declared')
    expected = { _id: document.id, name: 'example', display_name: 'EXAMPLE' }
    expect(document.as_json).to eq(expected)
    expect([document].as_json).to eq([expected])
    expect(document.as_json(properties: :all)).to eq(expected.merge(secret: 'hidden'))
  end

  it 'retains the normal field cache and invalidation behavior' do
    document = AllFieldsDocument.create!(name: 'example')
    document.as_json
    document.name = 'unsaved'
    expect(document.as_json[:name]).to eq('example')
    document.save!
    expect(document.as_json[:name]).to eq('unsaved')
  end

  it 'does not expose extra fields for ordinary explicit declarations' do
    document = JsonFoobar.create!(foo: 'visible', bar: 'private')
    expect(document.as_json).not_to have_key(:bar)
    expect(document.as_json).not_to have_key(:_id)
  end
end
