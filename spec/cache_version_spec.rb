require 'spec_helper'

describe 'Schema cache versions' do
  before do
    class VersionedDocument
      include Mongoid::Document
      include Mongoid::CachedJson
      field :value
      json_fields cache_version: 1, value: {}
    end
  end

  after do
    VersionedDocument.delete_all
    Object.send(:remove_const, :VersionedDocument)
  end

  [true, false].each do |bulk|
    context "with bulk reads #{bulk}" do
      before do
        @store = ActiveSupport::Cache::MemoryStore.new
        @store.singleton_class.send(:undef_method, :read_multi) unless bulk
        Mongoid::CachedJson.config.cache = @store
      end

      it 'separates new schema fragments without changing the API version' do
        document = VersionedDocument.create!(value: 'old')
        expect(document.as_json).to eq(value: 'old')
        document.value = 'new'
        expect(document.as_json).to eq(value: 'old')
        VersionedDocument.cached_json_cache_version = 2
        expect(document.as_json).to eq(value: 'new')
        VersionedDocument.cached_json_cache_version = 1
        expect(document.as_json).to eq(value: 'old')
      end

      it 'invalidates the current namespace on a model update' do
        document = VersionedDocument.create!(value: 'old')
        [1, 2].each do |version|
          VersionedDocument.cached_json_cache_version = version
          document.as_json
        end
        document.update_attributes!(value: 'new')
        expect(document.as_json).to eq(value: 'new')
        VersionedDocument.cached_json_cache_version = 1
        expect(document.as_json).to eq(value: 'old')
      end

      it 'uses the schema version for child fragments too' do
        document = VersionedDocument.create!(value: 'old')
        options = { properties: :short, version: :unspecified, is_top_level_json: false }
        key = VersionedDocument.cached_json_key(options, VersionedDocument, document.id)
        expect(key).to end_with('/false/schema/1')
        expect([document].as_json).to eq([{ value: 'old' }])
      end
    end
  end
end
