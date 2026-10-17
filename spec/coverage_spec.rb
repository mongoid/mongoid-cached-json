require 'spec_helper'

describe 'Cached JSON boundary contracts' do
  before do
    stub_const('PlainCoverageDocument', Class.new)
    PlainCoverageDocument.class_eval do
      include Mongoid::Document
      field :name, type: String
    end
  end

  after do
    PlainCoverageDocument.delete_all
  end

  it 'serializes criteria for models that do not include CachedJson' do
    document = PlainCoverageDocument.create!(name: 'plain')
    json = PlainCoverageDocument.where(id: document.id).as_json
    expect(json.first['name']).to eq('plain')
  end

  it 'applies configured transforms to uncached fields' do
    stub_const('TransformCoverageDocument', Class.new)
    TransformCoverageDocument.class_eval do
      include Mongoid::Document
      include Mongoid::CachedJson
      field :value
      json_fields value: { cache: false }
    end
    begin
      Mongoid::CachedJson.config.transform << ->(_field, _definition, value) { value.upcase }
      document = TransformCoverageDocument.create!(value: 'fresh')
      expect(document.as_json).to eq(value: 'FRESH')
    ensure
      TransformCoverageDocument.delete_all
    end
  end
end

describe Mongoid::CachedJson do
  it 'loads its standalone semantic version' do
    hide_const('Mongoid::CachedJson::VERSION')
    begin
      load File.expand_path('../lib/mongoid-cached-json/version.rb', __dir__)
      expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    ensure
      described_class.send(:remove_const, :VERSION) if described_class.const_defined?(:VERSION)
    end
  end
end
