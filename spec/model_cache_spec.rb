require 'spec_helper'

describe 'Per-model cache policy' do
  before do
    class UncachedDocument
      include Mongoid::Document
      include Mongoid::CachedJson
      field :value
      json_fields disable_caching: true, value: {}
    end

    class CachedContainer
      include Mongoid::Document
      include Mongoid::CachedJson
      field :value
      attr_accessor :child

      json_fields value: {}, child: { type: :reference }
    end
  end

  after do
    [UncachedDocument, CachedContainer].each(&:delete_all)
    [:UncachedDocument, :CachedContainer].each { |name| Object.send(:remove_const, name) }
  end

  [true, false].each do |bulk|
    context "with bulk reads #{bulk}" do
      before do
        @store = ActiveSupport::Cache::MemoryStore.new
        @store.singleton_class.send(:undef_method, :read_multi) unless bulk
        Mongoid::CachedJson.config.cache = @store
      end

      it 'does not read or write shared cache for a disabled model' do
        document = UncachedDocument.create!(value: 'first')
        expect(@store).not_to receive(:read_multi)
        expect(@store).not_to receive(:fetch)
        expect(@store).not_to receive(:write)
        expect(document.as_json).to eq(value: 'first')
        document.value = 'second'
        expect([document].as_json).to eq([{ value: 'second' }])
      end

      it 'keeps the parent cached while recomputing a disabled child' do
        parent = CachedContainer.create!(value: 'parent')
        child = UncachedDocument.create!(value: 'first')
        parent.child = child
        expect(parent.as_json).to eq(value: 'parent', child: { value: 'first' })
        parent.value = 'not saved'
        child.value = 'second'
        expect(parent.as_json).to eq(value: 'parent', child: { value: 'second' })
      end

      it 'does not disable caching on other models' do
        expect(CachedContainer.cached_json_disable_caching).to be_falsey
        document = CachedContainer.create!(value: 'first')
        document.as_json
        document.value = 'second'
        expect(document.as_json[:value]).to eq('first')
      end
    end
  end
end
