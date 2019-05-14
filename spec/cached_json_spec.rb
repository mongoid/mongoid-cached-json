require 'spec_helper'

describe Mongoid::CachedJson do
  it 'has a version' do
    expect(Mongoid::CachedJson::VERSION).not_to be_nil
    expect(Mongoid::CachedJson::VERSION.to_f).to be > 0
  end

  [:dalli_store, :memory_store].each do |cache_store|
    context "#{cache_store}" do
      before :each do
        @cache = Mongoid::CachedJson::Config.cache
        Mongoid::CachedJson.configure do |config|
          config.cache = ActiveSupport::Cache.lookup_store(cache_store)
        end
        if cache_store == :memory_store && Mongoid::CachedJson.config.cache.respond_to?(:read_multi)
          Mongoid::CachedJson.config.cache.instance_eval { undef :read_multi }
        end
      end
      after :each do
        Mongoid::CachedJson::Config.cache = @cache
      end
      context 'with basic fields defined for export with json_fields' do
        it 'returns public JSON if you nil options' do
          example = JsonFoobar.create(foo: 'FOO', baz: 'BAZ', bar: 'BAR')
          expect(example.as_json(nil)).to eq(example.as_json(properties: :short))
        end
        it 'allows subsets of fields to be returned by varying the properties definition' do
          example = JsonFoobar.create(foo: 'FOO', baz: 'BAZ', bar: 'BAR')
          # :short is a subset of the fields in :public and :public is a subset of the fields in :all
          expect(example.as_json(properties: :short)).to eq(:foo => 'FOO', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO')
          expect(example.as_json(properties: :public)).to eq(:foo => 'FOO', 'Baz' => 'BAZ', :bar => 'BAR', :default_foo => 'DEFAULT_FOO')
          expect(example.as_json(properties: :all)).to eq(:foo => 'FOO', :bar => 'BAR', 'Baz' => 'BAZ', :renamed_baz => 'BAZ', :default_foo => 'DEFAULT_FOO', :computed_field => 'FOOBAR')
        end
        it 'throws an error if you ask for an undefined property type' do
          expect { JsonFoobar.create.as_json(properties: :special) }.to raise_error(ArgumentError)
        end
        it "does not raise an error if you don't specify properties" do
          expect { JsonFoobar.create.as_json({}) }.to_not raise_error
        end
        it 'should hit the cache for subsequent as_json calls after the first' do
          foobar = JsonFoobar.create(foo: 'FOO', bar: 'BAR', baz: 'BAZ')
          all_result = foobar.as_json(properties: :all)
          public_result = foobar.as_json(properties: :public)
          short_result = foobar.as_json(properties: :short)
          expect(all_result).not_to eq(public_result)
          expect(all_result).not_to eq(short_result)
          expect(public_result).not_to eq(short_result)
          3.times { expect(foobar.as_json(properties: :all)).to eq(all_result) }
          3.times { expect(foobar.as_json(properties: :public)).to eq(public_result) }
          3.times { expect(foobar.as_json(properties: :short)).to eq(short_result) }
        end
        it 'should remove values from the cache when a model is saved' do
          foobar = JsonFoobar.create(foo: 'FOO', bar: 'BAR', baz: 'BAZ')
          all_result = foobar.as_json(properties: :all)
          public_result = foobar.as_json(properties: :public)
          short_result = foobar.as_json(properties: :short)
          foobar.foo = 'updated'
          # Not saved yet, so we should still be hitting the cache
          3.times { expect(foobar.as_json(properties: :all)).to eq(all_result) }
          3.times { expect(foobar.as_json(properties: :public)).to eq(public_result) }
          3.times { expect(foobar.as_json(properties: :short)).to eq(short_result) }
          foobar.save
          3.times { expect(foobar.as_json(properties: :all)).to eq(all_result.merge(foo: 'updated', computed_field: 'updatedBAR')) }
          3.times { expect(foobar.as_json(properties: :public)).to eq(public_result.merge(foo: 'updated')) }
          3.times { expect(foobar.as_json(properties: :short)).to eq(short_result.merge(foo: 'updated')) }
        end
      end
      context 'invalidate callbacks' do
        before :each do
          @foobar = JsonFoobar.create!(foo: 'FOO')
        end
        it 'should invalidate cache when a model is saved' do
          expect do
            @foobar.update_attributes!(foo: 'BAR')
          end.to invalidate @foobar
        end
        it 'should also invalidate cache when a model is saved without changes' do
          expect do
            @foobar.save!
          end.to invalidate @foobar
        end
        it 'should invalidate cache when a model is destroyed' do
          expect do
            @foobar.destroy
          end.to invalidate @foobar
        end
      end
      context 'many-to-one relationships' do
        it 'uses the correct properties on the base object and passes :short or :all as appropriate' do
          manager = JsonManager.create!(name: 'Boss')
          peon = manager.json_employees.create!(name: 'Peon')
          manager.json_employees.create!(name: 'Indentured servant')
          manager.json_employees.create!(name: 'Serf', nickname: 'Vince')
          3.times do
            3.times do
              manager_short_json = manager.as_json(properties: :short)
              expect(manager_short_json.length).to eq(2)
              expect(manager_short_json[:name]).to eq('Boss')
              expect(manager_short_json[:employees].member?(name: 'Peon')).to be_truthy
              expect(manager_short_json[:employees].member?(name: 'Indentured servant')).to be_truthy
              expect(manager_short_json[:employees].member?(name: 'Serf')).to be_truthy
              expect(manager_short_json[:employees].member?(nickname: 'Serf')).to be_falsey
            end
            3.times do
              manager_public_json = manager.as_json(properties: :public)
              expect(manager_public_json.length).to eq(2)
              expect(manager_public_json[:name]).to eq('Boss')
              expect(manager_public_json[:employees].member?(name: 'Peon')).to be_truthy
              expect(manager_public_json[:employees].member?(name: 'Indentured servant')).to be_truthy
              expect(manager_public_json[:employees].member?(name: 'Serf')).to be_truthy
              expect(manager_public_json[:employees].member?(nickname: 'Serf')).to be_falsey
            end
            3.times do
              manager_all_json = manager.as_json(properties: :all)
              expect(manager_all_json.length).to eq(3)
              expect(manager_all_json[:name]).to eq('Boss')
              expect(manager_all_json[:ssn]).to eq('123-45-6789')
              expect(manager_all_json[:employees].member?(name: 'Peon', nickname: 'My Favorite')).to be_truthy
              expect(manager_all_json[:employees].member?(name: 'Indentured servant', nickname: 'My Favorite')).to be_truthy
              expect(manager_all_json[:employees].member?(name: 'Serf', nickname: 'Vince')).to be_truthy
            end
            3.times do
              expect(peon.as_json(properties: :short)).to eq(name: 'Peon')
            end
            3.times do
              expect(peon.as_json(properties: :all)).to eq(name: 'Peon', nickname: 'My Favorite')
            end
          end
        end
        it 'correctly updates fields when either the parent or child class changes' do
          manager = JsonManager.create!(name: 'JsonManager')
          employee = manager.json_employees.create!(name: 'JsonEmployee')
          3.times do
            expect(manager.as_json(properties: :short)).to eq(name: 'JsonManager', employees: [{ name: 'JsonEmployee' }])
            expect(employee.as_json(properties: :short)).to eq(name: 'JsonEmployee')
          end
          manager.name = 'New JsonManager'
          manager.save
          3.times { expect(manager.as_json(properties: :short)).to eq(name: 'New JsonManager', employees: [{ name: 'JsonEmployee' }]) }
          employee.name = 'New JsonEmployee'
          employee.save
          3.times { expect(manager.as_json(properties: :short)).to eq(name: 'New JsonManager', employees: [{ name: 'New JsonEmployee' }]) }
        end
        context 'reference_properties' do
          it 'limits the json fields of a child relationship' do
            supervisor = JsonSupervisor.create(name: 'JsonSupervisor')
            manager = JsonManager.create(name: 'JsonManager', supervisor: supervisor)
            json = supervisor.as_json(properties: :all)
            expect(json[:managers][0].key?(:ssn)).to be_falsey
          end
        end
      end
      context 'one-to-one relationships' do
        before(:each) do
          @artwork = AwesomeArtwork.create(name: 'Mona Lisa')
        end
        it 'uses the correct properties on the base object and passes :all to any sub-objects for :all properties' do
          3.times do
            expect(@artwork.as_json(properties: :all)).to eq(name: 'Mona Lisa', image: nil)
          end
        end
        context 'with the relationship present' do
          before(:each) do
            @image = @artwork.create_awesome_image(name: 'Picture of Mona Lisa')
          end
          it 'uses the correct properties on the base object and passes :short to any sub-objects for :public and :short properties' do
            3.times do
              expect(@artwork.as_json(properties: :short)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Mona' })
              expect(@artwork.as_json(properties: :public)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Mona' })
              expect(@artwork.as_json(properties: :all)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Mona', url: 'http://example.com/404.html' })
              expect(@image.as_json(properties: :short)).to eq(name: 'Picture of Mona Lisa', nickname: 'Mona')
              expect(@image.as_json(properties: :public)).to eq(name: 'Picture of Mona Lisa', nickname: 'Mona', url: 'http://example.com/404.html')
            end
          end
          it 'uses the correct properties on the base object and passes :all to any sub-objects for :all properties' do
            3.times do
              expect(@artwork.as_json(properties: :all)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Mona', url: 'http://example.com/404.html' })
            end
          end
          it 'correctly updates fields when either the parent or child class changes' do
            # Call as_json for all properties so that the json will get cached
            [:short, :public, :all].each { |properties| @artwork.as_json(properties: properties) }
            @image.nickname = 'Worst Painting Ever'
            # Nothing has been saved yet, cached json for referenced document should reflect the truth in the database
            3.times do
              expect(@artwork.as_json(properties: :short)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Mona' })
              expect(@artwork.as_json(properties: :public)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Mona' })
              expect(@artwork.as_json(properties: :all)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Mona', url: 'http://example.com/404.html' })
            end
            @image.save
            3.times do
              expect(@artwork.as_json(properties: :short)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Worst Painting Ever' })
              expect(@artwork.as_json(properties: :public)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Worst Painting Ever' })
              expect(@artwork.as_json(properties: :all)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Worst Painting Ever', url: 'http://example.com/404.html' })
            end
            @image.name = 'Picture of Mona Lisa Watercolor'
            3.times do
              expect(@artwork.as_json(properties: :short)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Worst Painting Ever' })
              expect(@artwork.as_json(properties: :public)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Worst Painting Ever' })
              expect(@artwork.as_json(properties: :all)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa', nickname: 'Worst Painting Ever', url: 'http://example.com/404.html' })
            end
            @image.save
            3.times do
              expect(@artwork.as_json(properties: :short)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa Watercolor', nickname: 'Worst Painting Ever' })
              expect(@artwork.as_json(properties: :public)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa Watercolor', nickname: 'Worst Painting Ever' })
              expect(@artwork.as_json(properties: :all)).to eq(name: 'Mona Lisa', image: { name: 'Picture of Mona Lisa Watercolor', nickname: 'Worst Painting Ever', url: 'http://example.com/404.html' })
            end
          end
        end
      end
      context 'with a hide_as_child_json_when definition' do
        it 'should yield JSON when as_json is called directly and hide_as_child_json_when returns false on an instance' do
          c = SometimesSecret.create(should_tell_secret: true)
          expect(c.as_json(properties: :short)).to eq(secret: 'Afraid of the dark')
        end
        it 'should yield JSON when as_json is called directly and hide_as_child_json_when returns true on an instance' do
          c = SometimesSecret.create(should_tell_secret: false)
          expect(c.as_json(properties: :short)).to eq(secret: 'Afraid of the dark')
        end
        it 'should yield JSON without an instance of a child' do
          p = SecretParent.create(name: 'Parent')
          expect(p.as_json(properties: :all)[:child]).to be_nil
        end
        it 'should yield child JSON when as_json is called on the parent and hide_as_child_json_when returns false on an instance' do
          p = SecretParent.create(name: 'Parent')
          p.create_sometimes_secret(should_tell_secret: true)
          expect(p.as_json(properties: :short)[:child]).to eq(secret: 'Afraid of the dark')
        end
        it 'should not yield child JSON when as_json is called on the parent and hide_as_child_json_when returns true on an instance' do
          p = SecretParent.create(name: 'Parent')
          p.create_sometimes_secret(should_tell_secret: false)
          expect(p.as_json(properties: :short)).to eq(name: 'Parent', child: nil)
          expect(p.as_json(properties: :short)[:child]).to be_nil
        end
      end
      context 'relationships with a multi-level hierarchy' do
        before(:each) do
          @artwork = FastJsonArtwork.create
          @image = @artwork.create_fast_json_image
          @url1 = @image.fast_json_urls.create
          @url2 = @image.fast_json_urls.create
          @url3 = @image.fast_json_urls.create
          @common_url = @url1.url
        end
        it 'uses the correct properties on the base object and passes :short to any sub-objects for :short and :public' do
          3.times do
            expect(@artwork.as_json(properties: :short)).to eq(
              name: 'Artwork',
              image: { name: 'Image',
                       urls: [
                         { url: @common_url },
                         { url: @common_url },
                         { url: @common_url }
                       ]
              }
            )
            expect(@artwork.as_json(properties: :public)).to eq(
              name: 'Artwork',
              display_name: 'Awesome Artwork',
              image: { name: 'Image',
                       urls: [
                         { url: @common_url },
                         { url: @common_url },
                         { url: @common_url }
                       ]
              }
            )
          end
        end
        it 'uses the correct properties on the base object and passes :all to any sub-objects for :all' do
          3.times do
            expect(@artwork.as_json(properties: :all)).to eq(
              name: 'Artwork',
              display_name: 'Awesome Artwork',
              price: 1000,
              image: { name: 'Image',
                       urls: [
                         { url: @common_url, is_public: false },
                         { url: @common_url, is_public: false },
                         { url: @common_url, is_public: false }]
                }
            )
          end
        end
        it 'correctly updates json for all classes in the hierarchy when saves occur' do
          # Call as_json once to make sure the json is cached before we modify the referenced model locally
          @artwork.as_json(properties: :short)
          new_url = 'http://chee.sy/omg.jpg'
          @url1.url = new_url
          # No save has happened, so as_json shouldn't update yet
          3.times do
            expect(@artwork.as_json(properties: :short)).to eq(
              name: 'Artwork',
              image: { name: 'Image',
                       urls: [
                         { url: @common_url },
                         { url: @common_url },
                         { url: @common_url }
                       ]
              }
            )
          end
          @url1.save
          3.times do
            json = @artwork.as_json
            expect(json[:name]).to eq('Artwork')
            expect(json[:image][:name]).to eq('Image')
            expect(json[:image][:urls].map { |u| u[:url] }.sort).to eq([@common_url, @common_url, new_url].sort)
          end
        end
      end
      context 'transform' do
        context 'upcase' do
          before :each do
            Mongoid::CachedJson.config.transform do |_field, _definition, value|
              value.upcase
            end
          end
          it 'transforms every value in returned JSON' do
            expect(JsonFoobar.new(foo: 'foo', bar: 'Bar', baz: 'BAZ').as_json).to eq('Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO', :foo => 'FOO')
          end
        end
        context 'with options' do
          before :each do
            Mongoid::CachedJson.config.transform do |_field, definition, value|
              definition[:transform] ? value.send(definition[:transform].to_sym) : value
            end
          end
          it 'transforms every value in returned JSON using the :transform attribute' do
            expect(JsonTransform.new(upcase: 'upcase', downcase: 'DOWNCASE', nochange: 'eLiTe').as_json).to eq(upcase: 'UPCASE', downcase: 'downcase', nochange: 'eLiTe')
          end
        end
        context 'with multiple transformations' do
          before :each do
            Mongoid::CachedJson.config.transform do |_field, _definition, value|
              value.to_i + 1
            end
            Mongoid::CachedJson.config.transform do |_field, _definition, value|
              value.to_i / 2
            end
          end
          it 'transforms every value in returned JSON using the :transform attribute' do
            expect(JsonMath.new(number: 9).as_json).to eq(number: 5)
          end
        end
      end
      context 'with cache disabled' do
        before :each do
          allow(Mongoid::CachedJson.config).to receive(:disable_caching).and_return(true)
        end
        it 'forces a cache miss' do
          example = JsonFoobar.create(foo: 'FOO', baz: 'BAZ', bar: 'BAR')
          key = "as_json/unspecified/JsonFoobar/#{example.id}/short/true"
          case cache_store
          when :memory_store then
            expect(Mongoid::CachedJson.config.cache).to receive(:fetch).with(key, force: true).twice
          when :dalli_store then
            expect(Mongoid::CachedJson.config.cache).not_to receive(:write)
          else
            fail ArgumentError, "invalid cache store: #{cache_store}"
          end
          2.times { example.as_json }
        end
      end
      context 'versioning' do
        it 'returns JSON for version 2' do
          example = JsonFoobar.create(foo: 'FOO', baz: 'BAZ', bar: 'BAR')
          expect(example.as_json(properties: :short, version: :v2)).to eq(:foo => 'FOO', 'Taz' => 'BAZ', 'Naz' => 'BAZ', :default_foo => 'DEFAULT_FOO')
        end
        it 'returns JSON for version 3' do
          example = JsonFoobar.create(foo: 'FOO', baz: 'BAZ', bar: 'BAR')
          expect(example.as_json(properties: :short, version: :v3)).to eq(:foo => 'FOO', 'Naz' => 'BAZ', :default_foo => 'DEFAULT_FOO')
        end
        it "returns default JSON for version 4 that hasn't been declared" do
          example = JsonFoobar.create(foo: 'FOO', baz: 'BAZ', bar: 'BAR')
          expect(example.as_json(properties: :short, version: :v4)).to eq(foo: 'FOO', default_foo: 'DEFAULT_FOO')
        end
        it 'returns JSON for the default version' do
          Mongoid::CachedJson.config.default_version = :v2
          example = JsonFoobar.create(foo: 'FOO', baz: 'BAZ', bar: 'BAR')
          expect(example.as_json(properties: :short)).to eq(:foo => 'FOO', 'Taz' => 'BAZ', 'Naz' => 'BAZ', :default_foo => 'DEFAULT_FOO')
        end
        it 'returns correct JSON for Person used in README' do
          person = Person.create(first: 'John', middle: 'F.', last: 'Kennedy', born: 'May 29, 1917')
          expect(person.as_json).to eq(name: 'John F. Kennedy')
          expect(person.as_json(version: :v2)).to eq(first: 'John', middle: 'F.', last: 'Kennedy', name: 'John F. Kennedy')
          expect(person.as_json(version: :v3)).to eq(first: 'John', middle: 'F.', last: 'Kennedy', name: 'John F. Kennedy', born: 'May 29, 1917')
        end
      end
      context 'polymorphic objects' do
        before(:each) do
          @json_embedded_foobar = JsonEmbeddedFoobar.new(foo: 'embedded')
          @json_referenced_foobar = JsonReferencedFoobar.new(foo: 'referenced')
          @json_parent_foobar = JsonParentFoobar.create(
            json_polymorphic_embedded_foobar: @json_embedded_foobar,
            json_polymorphic_referenced_foobar: @json_referenced_foobar
          )
          @json_referenced_foobar.save!

          # Cache...
          [:all, :short, :public].each do |prop|
            @json_parent_foobar.as_json(properties: prop)
          end
        end
        it 'returns correct JSON when a child (embedded) polymorphic document is changed' do
          expect(@json_parent_foobar.as_json(properties: :all)[:json_polymorphic_embedded_foobar][:foo]).to eq('embedded')
          expect(@json_embedded_foobar.as_json(properties: :all)[:foo]).to eq('embedded')
          @json_embedded_foobar.update_attributes!(foo: 'EMBEDDED')
          expect(@json_embedded_foobar.as_json(properties: :all)[:foo]).to eq('EMBEDDED')
          expect(@json_parent_foobar.as_json(properties: :all)[:json_polymorphic_embedded_foobar][:foo]).to eq('EMBEDDED')
        end
        it 'returns correct JSON when a child (referenced) polymorphic document is changed' do
          expect(@json_parent_foobar.as_json(properties: :all)[:json_polymorphic_referenced_foobar][:foo]).to eq('referenced')
          expect(@json_referenced_foobar.as_json(properties: :all)[:foo]).to eq('referenced')
          @json_referenced_foobar.update_attributes!(foo: 'REFERENCED')
          expect(@json_referenced_foobar.as_json(properties: :all)[:foo]).to eq('REFERENCED')
          expect(@json_parent_foobar.as_json(properties: :all)[:json_polymorphic_referenced_foobar][:foo]).to eq('REFERENCED')
        end
      end
      context 'polymorphic relationships' do
        before :each do
          @company = PolyCompany.create!
          @company_post = PolyPost.create!(postable: @company)
          @person = PolyPerson.create!
          @person_post = PolyPost.create!(postable: @person)
        end
        it 'returns the correct JSON' do
          expect(@company_post.as_json).to eq(parent: { id: @company.id, type: 'PolyCompany' })
          expect(@person_post.as_json).to eq(parent: { id: @person.id, type: 'PolyPerson' })
        end
      end
      context 'cache key' do
        it 'correctly generates a cached json key' do
          example = JsonFoobar.create(foo: 'FOO', baz: 'BAZ', bar: 'BAR')
          expect(JsonFoobar.cached_json_key({ properties: :short, is_top_level_json: true, version: :v1 }, example.class, example.id)).to eq("as_json/v1/JsonFoobar/#{example.id}/short/true")
        end
      end
      context 'embeds_many relationships' do
        before :each do
          @cell = PrisonCell.create!(number: 42)
          @cell.inmates.create!(nickname: 'Joe', person: Person.create!(first: 'Joe'))
          @cell.inmates.create!(nickname: 'Bob', person: Person.create!(first: 'Bob'))
        end
        it 'returns the correct JSON' do
          expect(@cell.as_json(properties: :all)).to eq(number: 42,
                                                        inmates: [
                                                          { nickname: 'Joe', person: { name: 'Joe' } },
                                                          { nickname: 'Bob', person: { name: 'Bob' } }
                                                        ]
                                                       )
        end
      end
      context 'with repeated objects in the JSON' do
        before :each do
          @cell = PrisonCell.create!(number: 42)
          @person = Person.create!(first: 'Evil')
          @cell.inmates.create!(nickname: 'Joe', person: @person)
          @cell.inmates.create!(nickname: 'Bob', person: @person)
        end
        it 'returns the correct JSON' do
          expect(@cell.as_json(properties: :all)).to eq(number: 42,
                                                        inmates: [
                                                          { nickname: 'Joe', person: { name: 'Evil' } },
                                                          { nickname: 'Bob', person: { name: 'Evil' } }
                                                        ]
                                                       )
        end
      end
      context 'belongs_to relationship' do
        before :each do
          @tool = Tool.create!(name: 'hammer')
        end
        it 'returns a nil reference' do
          expect(@tool.as_json(properties: :all)).to eq(tool_box: nil, name: 'hammer')
        end
        context 'persisted' do
          before :each do
            @tool_box = ToolBox.create!(color: 'red')
            @tool.update_attributes!(tool_box: @tool_box)
          end
          it 'returns a reference' do
            expect(@tool.as_json(properties: :all)).to eq(tool_box: { color: 'red' }, name: 'hammer')
          end
        end
      end
      context 'many-to-many relationships' do
        before :each do
          @image = FastJsonImage.create!
        end
        it 'resolves a default empty relationship' do
          expect(@image.as_json(properties: :all)).to eq(name: 'Image', urls: [])
        end
        it 'resolves a nil relationship on destroy' do
          @image.destroy
          expect(@image.as_json(properties: :all)).to eq(name: 'Image', urls: [])
        end
      end
    end
  end
end
