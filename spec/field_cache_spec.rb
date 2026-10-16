require 'spec_helper'

describe 'Per-field cache policy' do
  before do
    class FieldCacheDocument
      include Mongoid::Document
      include Mongoid::CachedJson

      field :stored
      field :live

      json_fields stored: {}, live: { cache: false }
    end

    class FieldCacheChild
      include Mongoid::Document
      include Mongoid::CachedJson

      field :value

      json_fields value: {}
    end

    class FieldCacheParent
      include Mongoid::Document
      include Mongoid::CachedJson

      field :name
      attr_accessor :child

      json_fields name: {}, child: { type: :reference, cache: false }
    end
  end

  after do
    [FieldCacheDocument, FieldCacheChild, FieldCacheParent].each(&:delete_all)
    [:FieldCacheDocument, :FieldCacheChild, :FieldCacheParent].each { |name| Object.send(:remove_const, name) }
  end

  [true, false].each do |bulk|
    context "with bulk reads #{bulk}" do
      before do
        @store = ActiveSupport::Cache::MemoryStore.new
        @store.singleton_class.send(:undef_method, :read_multi) unless bulk
        Mongoid::CachedJson.config.cache = @store
      end

      it 'recomputes an individual callable field without refreshing cached siblings' do
        document = FieldCacheDocument.create!(stored: 'stored', live: 'first')
        expect(document.as_json).to eq(stored: 'stored', live: 'first')

        document.stored = 'unsaved'
        document.live = 'second'
        expect(document.as_json).to eq(stored: 'stored', live: 'second')
      end

      it 'bypasses the referenced model cache only for this field' do
        parent = FieldCacheParent.create!(name: 'parent')
        child = FieldCacheChild.create!(value: 'first')
        parent.child = child
        options = { properties: :short, version: :unspecified, is_top_level_json: false }
        key = FieldCacheChild.cached_json_key(options, FieldCacheChild, child.id)

        expect(parent.as_json).to eq(name: 'parent', child: { value: 'first' })
        expect(@store.read(key)).to be_nil

        child.value = 'second'
        expect(parent.as_json).to eq(name: 'parent', child: { value: 'second' })
        expect(@store.read(key)).to be_nil
      end
    end
  end
end
