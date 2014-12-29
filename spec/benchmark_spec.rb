require 'spec_helper'
require 'benchmark'
require 'active_support/cache/dalli_store'

describe Mongoid::CachedJson do
  before(:all) do
    @n = 100
    puts "Benchmarking #{Mongoid::CachedJson::VERSION} with #{RUBY_DESCRIPTION}, Dalli #{Dalli::VERSION}"
  end

  before do
    # flat record
    @flat = JsonFoobar.create!(foo: SecureRandom.uuid, baz: SecureRandom.uuid, bar: SecureRandom.uuid)
    # has_many
    @manager = JsonManager.create(name: 'Boss')
    @manager.json_employees.create(name: 'Peon')
    @manager.json_employees.create(name: 'Indentured servant')
    @manager.json_employees.create(name: 'Serf', nickname: 'Vince')
    # has_one
    @artwork = AwesomeArtwork.create(name: 'Mona Lisa')
    @artwork.create_awesome_image(name: 'Picture of Mona Lisa')
    # child and parent with secrets
    @child_secret = SometimesSecret.create(should_tell_secret: true)
    @child_not_secret = SometimesSecret.create(should_tell_secret: false)
    @parent_with_secret = SecretParent.create(name: 'Parent')
    @parent_with_secret.create_sometimes_secret(should_tell_secret: true)
    # habtm
    @habtm = FastJsonArtwork.create
    @habtm_image = @habtm.create_fast_json_image
    @habtm_image.fast_json_urls.create
    @habtm_image.fast_json_urls.create
    @habtm_image.fast_json_urls.create
    # transform
    Mongoid::CachedJson.config.transform do |_field, definition, value|
      definition[:transform] ? value.send(definition[:transform].to_sym) : value
    end
    @transform = JsonTransform.create!(upcase: 'upcase', downcase: 'DOWNCASE', nochange: 'eLiTe')
    # polymorphic
    @embedded = JsonEmbeddedFoobar.new(foo: 'embedded')
    @referenced = JsonReferencedFoobar.new(foo: 'referenced')
    @poly_parent = JsonParentFoobar.create!(
      json_polymorphic_embedded_foobar: @embedded,
      json_polymorphic_referenced_foobar: @referenced
    )
    @referenced.save!
    # polymorphic relationships
    @company = PolyCompany.create!
    @company_post = PolyPost.create!(postable: @company)
    @person = PolyPerson.create!
    @person_post = PolyPost.create!(postable: @person)
    # embeds_many
    @cell = PrisonCell.create!(number: 42)
    @cell.inmates.create!(nickname: 'Joe', person: Person.create!(first: 'Joe'))
    @cell.inmates.create!(nickname: 'Bob', person: Person.create!(first: 'Bob'))
    # belongs_to
    @tool_box = ToolBox.create!(color: 'red')
    @hammer = Tool.create!(name: 'hammer', tool_box: @tool_box)
    @screwdriver = Tool.create!(name: 'screwdriver', tool_box: @tool_box)
    @saw = Tool.create!(name: 'saw', tool_box: @tool_box)
  end

  [:dalli_store, :memory_store].each do |cache_store|
    context cache_store do
      before :each do
        @cache = Mongoid::CachedJson::Config.cache
        Mongoid::CachedJson.configure do |config|
          config.cache = ActiveSupport::Cache.lookup_store(cache_store)
          config.cache.clear
        end
      end
      after :each do
        Mongoid::CachedJson::Config.cache = @cache
      end

      it 'benchmark' do
        all_times = []
        [
          :flat, :manager, :artwork,
          :child_secret, :child_not_secret, :parent_with_secret,
          :habtm, :habtm_image,
          :transform,
          :poly_parent, :embedded, :referenced,
          :company, :person, :company_post, :person_post,
          :cell,
          :tool_box, :hammer, :screwdriver, :saw
        ].each do |record|
          times = []
          times << Benchmark.realtime do
            [:short, :public, :all].each do |properties|
              instance = instance_variable_get("@#{record}".to_sym)
              expect(instance).not_to be_nil
              @n.times do
                # instance
                json = instance.as_json(properties: properties)
                expect(json).not_to be_nil
                expect(json).not_to eq({})
              end
              # class
              if instance.class.respond_to?(:all)
                json = instance.class.all.as_json(properties: properties)
                expect(json).not_to be_nil
              end
            end
          end
          all_times.concat(times)
          avg = times.reduce { |sum, time| sum + time } / times.size
          puts "#{cache_store}:#{record} => #{avg}"
        end
        avg = all_times.reduce { |sum, time| sum + time } / all_times.size
        puts '=' * 40
        puts "#{cache_store} => #{avg}"
      end
    end
  end
end
