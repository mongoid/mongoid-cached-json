require 'spec_helper'

describe Mongoid::CachedJson do
  it "has a version" do
    Mongoid::CachedJson::VERSION.should_not be_nil
    Mongoid::CachedJson::VERSION.to_f.should > 0
  end
  context "with basic fields defined for export with json_fields" do
    it "returns public JSON if you nil options" do
      example = JsonFoobar.create({ :foo => "FOO", :baz => "BAZ", :bar => "BAR" })
      example.as_json(nil).should == example.as_json({ :properties => :short })
    end
    it "allows subsets of fields to be returned by varying the properties definition" do
      example = JsonFoobar.create({ :foo => "FOO", :baz => "BAZ", :bar => "BAR" })
      # :short is a subset of the fields in :public and :public is a subset of the fields in :all
      example.as_json({ :properties => :short }).should == { :foo => "FOO", "Baz" => "BAZ", :default_foo => "DEFAULT_FOO"}
      example.as_json({ :properties => :public }).should == { :foo => "FOO", "Baz" => "BAZ", :bar => "BAR", :default_foo => "DEFAULT_FOO"}
      example.as_json({ :properties => :all }).should == { :foo => "FOO", :bar => "BAR", "Baz" => "BAZ", :renamed_baz => "BAZ", :default_foo => "DEFAULT_FOO", :computed_field => "FOOBAR" }
    end
    it "throws an error if you ask for an undefined property type" do
      lambda { JsonFoobar.create.as_json({ :properties => :special }) }.should raise_error(ArgumentError)
    end
    it "does not raise an error if you don't specify properties" do
      lambda { JsonFoobar.create.as_json({ }) }.should_not raise_error
    end
    it "should hit the cache for subsequent as_json calls after the first" do
      foobar = JsonFoobar.create({ :foo => "FOO", :bar => "BAR", :baz => "BAZ" })
      all_result = foobar.as_json({ :properties => :all })
      public_result = foobar.as_json({ :properties => :public })
      short_result = foobar.as_json({ :properties => :short })
      all_result.should_not == public_result
      all_result.should_not == short_result
      public_result.should_not == short_result
      3.times { foobar.as_json({ :properties => :all }).should == all_result }
      3.times { foobar.as_json({ :properties => :public }).should == public_result }
      3.times { foobar.as_json({ :properties => :short }).should == short_result }
    end
    it "should remove values from the cache when a model is saved" do
      foobar = JsonFoobar.create(:foo => "FOO", :bar => "BAR", :baz => "BAZ")
      all_result = foobar.as_json({ :properties => :all })
      public_result = foobar.as_json({ :properties => :public })
      short_result = foobar.as_json({ :properties => :short })
      foobar.foo = "foo"
      # Not saved yet, so we should still be hitting the cache
      3.times { foobar.as_json({ :properties => :all }).should == all_result }
      3.times { foobar.as_json({ :properties => :public }).should == public_result }
      3.times { foobar.as_json({ :properties => :short }).should == short_result }
      foobar.save
      3.times { foobar.as_json({ :properties => :all }).should == all_result.merge({ :foo => "foo", :computed_field => "fooBAR" }) }
      3.times { foobar.as_json({ :properties => :public }).should == public_result.merge({ :foo => "foo" }) }
      3.times { foobar.as_json({ :properties => :short }).should == short_result.merge({ :foo => "foo" }) }
    end
    it "should invalidate cache when a model is saved" do
      foobar = JsonFoobar.create(:foo => "FOO")
      lambda {
        foobar.update_attributes(:foo => "BAR")
      }.should invalidate foobar
    end
  end
  context "many-to-one relationships" do
    it "uses the correct properties on the base object and passes :short or :all as appropriate" do
      manager = JsonManager.create({ :name => "Boss" })
      peon = manager.json_employees.create({ :name => "Peon" })
      manager.json_employees.create({ :name => "Indentured servant" })
      manager.json_employees.create({ :name => "Serf", :nickname => "Vince" })
      3.times do
        3.times do
          manager_short_json = manager.as_json({ :properties => :short })
          manager_short_json.length.should == 2
          manager_short_json[:name].should == "Boss"
          manager_short_json[:employees].member?({ :name => "Peon" }).should be_true
          manager_short_json[:employees].member?({ :name => "Indentured servant" }).should be_true
          manager_short_json[:employees].member?({ :name => "Serf" }).should be_true
          manager_short_json[:employees].member?({ :nickname => "Serf" }).should be_false
        end
        3.times do
          manager_public_json = manager.as_json({ :properties => :public })
          manager_public_json.length.should == 2
          manager_public_json[:name].should == "Boss"
          manager_public_json[:employees].member?({ :name => "Peon" }).should be_true
          manager_public_json[:employees].member?({ :name => "Indentured servant" }).should be_true
          manager_public_json[:employees].member?({ :name => "Serf" }).should be_true
          manager_public_json[:employees].member?({ :nickname => "Serf" }).should be_false
        end
        3.times do
          manager_all_json = manager.as_json({ :properties => :all })
          manager_all_json.length.should == 3
          manager_all_json[:name].should == "Boss"
          manager_all_json[:ssn].should == "123-45-6789"
          manager_all_json[:employees].member?({ :name => "Peon", :nickname => "My Favorite" }).should be_true
          manager_all_json[:employees].member?({ :name => "Indentured servant", :nickname => "My Favorite" }).should be_true
          manager_all_json[:employees].member?({ :name => "Serf", :nickname => "Vince" }).should be_true
        end
        3.times do
          peon.as_json({ :properties => :short }).should == { :name => "Peon" }
        end
        3.times do
          peon.as_json({ :properties => :all }).should == { :name => "Peon", :nickname => "My Favorite" }
        end
      end
    end
    it "correctly updates fields when either the parent or child class changes" do
      manager = JsonManager.create({ :name => "JsonManager" })
      employee = manager.json_employees.create({ :name => "JsonEmployee" })
      3.times do
        manager.as_json({ :properties => :short }).should == { :name => "JsonManager", :employees => [ { :name => "JsonEmployee" } ] }
        employee.as_json({ :properties => :short }).should == { :name => "JsonEmployee" }
      end
      manager.name = "New JsonManager"
      manager.save
      3.times { manager.as_json({ :properties => :short }).should == { :name => "New JsonManager", :employees => [ { :name => "JsonEmployee" } ] } }
      employee.name = "New JsonEmployee"
      employee.save
      3.times { manager.as_json({ :properties => :short }).should == { :name => "New JsonManager", :employees => [ { :name => "New JsonEmployee" } ] } }
    end
  end
  context "one-to-one relationships" do
    before(:each) do
      @artwork = AwesomeArtwork.create({ :name => "Mona Lisa" })
      @image = @artwork.create_awesome_image({ :name => "Picture of Mona Lisa" })
    end
    it "uses the correct properties on the base object and passes :short to any sub-objects for :public and :short properties" do
      3.times do
        @artwork.as_json({ :properties => :short }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Mona" } }
        @artwork.as_json({ :properties => :public }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Mona" } }
        @artwork.as_json({ :properties => :all }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Mona", :url => "http://example.com/404.html" } }
        @image.as_json({ :properties => :short }).should == { :name => "Picture of Mona Lisa", :nickname => "Mona" }
        @image.as_json({ :properties => :public }).should == { :name => "Picture of Mona Lisa", :nickname => "Mona", :url => "http://example.com/404.html" }
      end
    end
    it "uses the correct properties on the base object and passes :all to any sub-objects for :all properties" do
      3.times do
        @artwork.as_json({ :properties => :all }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Mona", :url => "http://example.com/404.html" } }
      end
    end
    it "correctly updates fields when either the parent or child class changes" do
      # Call as_json for all properties so that the json will get cached
      [:short, :public, :all].each { |properties| @artwork.as_json({ :properties => properties }) }
      @image.nickname = "Worst Painting Ever"
      # Nothing has been saved yet, cached json for referenced document should reflect the truth in the database
      3.times do
        @artwork.as_json({ :properties => :short }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Mona" } }
        @artwork.as_json({ :properties => :public }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Mona" } }
        @artwork.as_json({ :properties => :all }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Mona", :url => "http://example.com/404.html" } }
      end
      @image.save
      3.times do
        @artwork.as_json({ :properties => :short }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Worst Painting Ever" } }
        @artwork.as_json({ :properties => :public }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Worst Painting Ever" } }
        @artwork.as_json({ :properties => :all }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Worst Painting Ever", :url => "http://example.com/404.html" } }
      end
      @image.name = "Picture of Mona Lisa Watercolor"
      3.times do
        @artwork.as_json({ :properties => :short }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Worst Painting Ever" } }
        @artwork.as_json({ :properties => :public }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Worst Painting Ever" } }
        @artwork.as_json({ :properties => :all }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa", :nickname => "Worst Painting Ever", :url => "http://example.com/404.html" } }
      end
      @image.save
      3.times do
        @artwork.as_json({ :properties => :short }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa Watercolor", :nickname => "Worst Painting Ever" } }
        @artwork.as_json({ :properties => :public }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa Watercolor", :nickname => "Worst Painting Ever" } }
        @artwork.as_json({ :properties => :all }).should == { :name => "Mona Lisa", :image => { :name => "Picture of Mona Lisa Watercolor", :nickname => "Worst Painting Ever", :url => "http://example.com/404.html" } }
      end
    end
  end
  context "with a hide_as_child_json_when definition" do
    it "should yield JSON when as_json is called directly and hide_as_child_json_when returns false on an instance" do
      c = SometimesSecret.create({ :should_tell_secret => true })
      c.as_json({ :properties => :short }).should == { :secret => "Afraid of the dark" }
    end
    it "should yield JSON when as_json is called directly and hide_as_child_json_when returns true on an instance" do
      c = SometimesSecret.create({ :should_tell_secret => false })
      c.as_json({ :properties => :short }).should == { :secret => "Afraid of the dark" }
    end
    it "should yield child JSON when as_json is called on the parent and hide_as_child_json_when returns false on an instance" do
      p = SecretParent.create({ :name => "Parent" })
      p.create_sometimes_secret({ :should_tell_secret => true })
      p.as_json({ :properties => :short })[:child].should == { :secret => "Afraid of the dark" }
    end
    it "should not yield child JSON when as_json is called on the parent and hide_as_child_json_when returns true on an instance" do
      p = SecretParent.create({ :name => "Parent" })
      p.create_sometimes_secret({ :should_tell_secret => false })
      p.as_json({ :properties => :short }).should == { :name => "Parent", :child => nil }
      p.as_json({ :properties => :short })[:child].should be_nil
    end
  end
  context "relationships with a multi-level hierarchy" do
    before(:each) do
      @artwork = FastJsonArtwork.create
      @image = @artwork.create_fast_json_image
      @url1 = @image.fast_json_urls.create
      @url2 = @image.fast_json_urls.create
      @url3 = @image.fast_json_urls.create
      @common_url = @url1.url
    end
    it "uses the correct properties on the base object and passes :short to any sub-objects for :short and :public" do
      3.times do
        @artwork.as_json({ :properties => :short }).should == {
          :name => "Artwork",
          :image => { :name => "Image",
            :urls => [
              { :url => @common_url },
              { :url => @common_url },
              { :url => @common_url }
            ]
          }
        }
        @artwork.as_json({ :properties => :public }).should == {
          :name => "Artwork",
          :display_name => "Awesome Artwork",
          :image => { :name => "Image",
            :urls => [
              { :url => @common_url },
              { :url => @common_url },
              { :url => @common_url }
            ]
          }
        }
      end
    end
    it "uses the correct properties on the base object and passes :all to any sub-objects for :all" do
      3.times do
        @artwork.as_json({ :properties => :all }).should == {
          :name => "Artwork",
          :display_name => "Awesome Artwork",
          :price => 1000,
          :image => { :name => "Image",
            :urls => [
              { :url => @common_url, :is_public => false },
              { :url => @common_url, :is_public => false },
              { :url => @common_url, :is_public => false } ]
            }
        }
      end
    end
    it "correctly updates json for all classes in the hierarchy when saves occur" do
      # Call as_json once to make sure the json is cached before we modify the referenced model locally
      @artwork.as_json({ :properties => :short })
      new_url = "http://chee.sy/omg.jpg"
      @url1.url = new_url
      # No save has happened, so as_json shouldn't update yet
      3.times do
        @artwork.as_json({ :properties => :short }).should == {
          :name => "Artwork",
          :image => { :name => "Image",
            :urls => [
              { :url => @common_url },
              { :url => @common_url },
              { :url => @common_url }
            ]
          }
        }
      end
      @url1.save
      3.times do
        json = @artwork.as_json
        json[:name].should == "Artwork"
        json[:image][:name].should == "Image"
        json[:image][:urls].map{ |u| u[:url] }.sort.should == [@common_url, @common_url, new_url].sort
      end
    end
  end
  context "transform" do
    context "upcase" do
      before :each do
        Mongoid::CachedJson.config.transform do |field, definition, value|
          value.upcase
        end
      end
      it "transforms every value in returned JSON" do
        JsonFoobar.new({ :foo => "foo", :bar => "Bar", :baz => "BAZ" }).as_json.should == { "Baz" => "BAZ", :default_foo => "DEFAULT_FOO", :foo => "FOO" }
      end
    end
    context "with options" do
      before :each do
        Mongoid::CachedJson.config.transform do |field, definition, value|
          definition[:transform] ? value.send(definition[:transform].to_sym) : value
        end
      end
      it "transforms every value in returned JSON using the :transform attribute" do
        JsonTransform.new({ :upcase => "upcase", :downcase => "DOWNCASE", :nochange => "eLiTe" }).as_json.should == { :upcase => "UPCASE", :downcase => "downcase", :nochange => "eLiTe" }
      end
    end
    context "with mutliple transformations" do
      before :each do
        Mongoid::CachedJson.config.transform do |field, definition, value|
          value.to_i + 1
        end
        Mongoid::CachedJson.config.transform do |field, definition, value|
          value.to_i / 2
        end
      end
      it "transforms every value in returned JSON using the :transform attribute" do
        JsonMath.new({ :number => 9 }).as_json.should == { :number => 5 }
      end
    end
  end
  context "with cache disabled" do
    before :each do
      Mongoid::CachedJson.config.disable_caching = true
    end
    it "forces a cache miss" do
      example = JsonFoobar.create({ :foo => "FOO", :baz => "BAZ", :bar => "BAR" })
      Mongoid::CachedJson.config.cache.should_receive(:fetch).with("as_json/unspecified/JsonFoobar/#{example.id}/short/true", { :force => true }).twice
      example.as_json
      example.as_json
    end
  end
  context "versioning" do
    it "returns JSON for version 2" do
      example = JsonFoobar.create(:foo => "FOO", :baz => "BAZ", :bar => "BAR")
      example.as_json({ :properties => :short, :version => :v2 }).should == { :foo => "FOO", "Taz" => "BAZ", "Naz" => "BAZ", :default_foo => "DEFAULT_FOO" }
    end
    it "returns JSON for version 3" do
      example = JsonFoobar.create(:foo => "FOO", :baz => "BAZ", :bar => "BAR")
      example.as_json({ :properties => :short, :version => :v3 }).should == { :foo => "FOO", "Naz" => "BAZ", :default_foo => "DEFAULT_FOO" }
    end
    it "returns default JSON for version 4 that hasn't been declared" do
      example = JsonFoobar.create(:foo => "FOO", :baz => "BAZ", :bar => "BAR")
      example.as_json({ :properties => :short, :version => :v4 }).should == { :foo => "FOO", :default_foo => "DEFAULT_FOO" }
    end
    it "returns JSON for the default version" do
      Mongoid::CachedJson.config.default_version = :v2
      example = JsonFoobar.create(:foo => "FOO", :baz => "BAZ", :bar => "BAR")
      example.as_json({ :properties => :short }).should == { :foo => "FOO", "Taz" => "BAZ", "Naz" => "BAZ", :default_foo => "DEFAULT_FOO" }
    end
    it "returns correct JSON for Person used in README" do
      person = Person.create({ :first => "John", :middle => "F.", :last => "Kennedy", :born => "May 29, 1917" })
      person.as_json.should == { :name => "John F. Kennedy" }
      person.as_json({ :version => :v2 }).should == { :first => "John", :middle => "F.", :last => "Kennedy", :name => "John F. Kennedy" }
      person.as_json({ :version => :v3 }).should == { :first => "John", :middle => "F.", :last => "Kennedy", :name => "John F. Kennedy", :born => "May 29, 1917" }
    end
  end
  context "polymorphic objects" do
    before(:each) do
      @json_embedded_foobar = JsonEmbeddedFoobar.new(:foo => "embedded")
      @json_referenced_foobar = JsonReferencedFoobar.new(:foo => "referenced")
      @json_parent_foobar = JsonParentFoobar.create({
        :json_polymorphic_embedded_foobar => @json_embedded_foobar,
        :json_polymorphic_referenced_foobar => @json_referenced_foobar
      })
      @json_referenced_foobar.json_parent_foobar = @json_parent_foobar
      @json_referenced_foobar.save!

      # Cache...
      [:all, :short, :public].each do |prop|
        @json_parent_foobar.as_json(:properties => prop)
      end
    end
    it "returns correct JSON when a child (embedded) polymorphic document is changed" do
      @json_parent_foobar.as_json(:properties => :all)[:json_polymorphic_embedded_foobar][:foo].should == "embedded"
      @json_embedded_foobar.as_json(:properties => :all)[:foo].should == "embedded"
      @json_embedded_foobar.update_attributes!(:foo => "EMBEDDED")
      @json_embedded_foobar.as_json(:properties => :all)[:foo].should == "EMBEDDED"
      @json_parent_foobar.as_json(:properties => :all)[:json_polymorphic_embedded_foobar][:foo].should == "EMBEDDED"
    end
    it "returns correct JSON when a child (referenced) polymorphic document is changed" do
      @json_parent_foobar.as_json(:properties => :all)[:json_polymorphic_referenced_foobar][:foo].should == "referenced"
      @json_referenced_foobar.as_json(:properties => :all)[:foo].should == "referenced"
      @json_referenced_foobar.update_attributes!(:foo => "REFERENCED")
      @json_referenced_foobar.as_json(:properties => :all)[:foo].should == "REFERENCED"
      @json_parent_foobar.as_json(:properties => :all)[:json_polymorphic_referenced_foobar][:foo].should == "REFERENCED"
    end
  end
  context "polymorhphic relationships" do
    before :each do
      @company = PolyCompany.create!
      @company_post = PolyPost.create!({ :postable => @company })
      @person = PolyPerson.create!
      @person_post = PolyPost.create!({ :postable => @person })
    end
    it "returns the correct JSON" do
      @company_post.as_json.should == { :parent => { :id => @company.id, :type => "PolyCompany" } }
      @person_post.as_json.should == { :parent => { :id => @person.id, :type => "PolyPerson" } }
    end
  end
  context "cache key" do
    it "correctly generates a cached json key" do
      example = JsonFoobar.create(:foo => "FOO", :baz => "BAZ", :bar => "BAR")
      JsonFoobar.cached_json_key({:properties => :short, :is_top_level_json => true, :version => :v1}, example.class, example.id).should == "as_json/v1/JsonFoobar/#{example.id.to_s}/short/true"
    end
  end
  context "embeds_many relationships" do
    before :each do
      @cell = PrisonCell.create!({ :number => 42 })
      @cell.inmates.create!({ :nickname => "Joe", :person => Person.create!({ :first => "Joe" }) })
      @cell.inmates.create!({ :nickname => "Bob", :person => Person.create!({ :first => "Bob" }) })
    end
    it "returns the correct JSON" do
      @cell.as_json({ :properties => :all }).should == { :number => 42,
        :inmates => [
          { :nickname => "Joe", :person => { :name => "Joe" } },
          { :nickname => "Bob", :person => { :name => "Bob" } }
        ]
      }
    end
  end
end

