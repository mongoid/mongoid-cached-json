Mongoid::CachedJson
===================

[![Gem Version](https://badge.fury.io/rb/mongoid-cached-json.svg)](http://badge.fury.io/rb/mongoid-cached-json)
[![Test](https://github.com/mongoid/mongoid-cached-json/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/mongoid/mongoid-cached-json/actions/workflows/test.yml?query=branch%3Amaster)
[![Coverage Status](https://coveralls.io/repos/github/mongoid/mongoid-cached-json/badge.svg?branch=master)](https://coveralls.io/github/mongoid/mongoid-cached-json?branch=master)

The Ruby 4.0 CI job measures library line coverage with SimpleCov and submits `coverage/.resultset.json` to Coveralls using GitHub's automatic token. Other matrix jobs do not submit duplicate reports. Run `COVERAGE=true bundle install` followed by `COVERAGE=true bundle exec rake spec` for a local report. The default-branch badge requires Coveralls to accept an upstream `master` build; configuring this workflow does not activate the external service.

Typical `as_json` definitions may involve lots of database point queries and method calls. When returning collections of objects, a single call may yield hundreds of database queries that can take seconds. This library mitigates the problem by implementing a module called `CachedJson`.

`CachedJson` enables returning multiple JSON formats and versions from a single class and provides some rules for yielding embedded or referenced data. It then uses a scheme where fragments of JSON are cached for a particular (class, id) pair containing only the data that doesn't involve references/embedded documents. To get the full JSON for an instance, `CachedJson` will combine fragments of JSON from the instance with fragments representing the JSON for its references. In the best case, when all of these fragments are cached, this falls through to a few cache lookups followed by a couple Ruby hash merges to create the JSON.

Using `Mongoid::CachedJson` we were able to cut our JSON API average response time by about a factor of 10.

Resources
---------

* [Need Help? Google Group](http://groups.google.com/group/mongoid-cached-json)
* [Source Code](http://github.com/mongoid/mongoid-cached-json)
* [Upgrading](UPGRADING.md)

Quickstart
----------

Add `mongoid-cached-json` to your Gemfile.

    gem 'mongoid-cached-json'

Include `Mongoid::CachedJson` in your models.

``` ruby
class Gadget
  include Mongoid::CachedJson

  field :name
  field :extras

  belongs_to :widget

  json_fields \
    name: {},
    extras: { properties: :public }

end

class Widget
  include Mongoid::CachedJson

  field :name
  has_many :gadgets

  json_fields \
    name: {},
    gadgets: { type: :reference, properties: :public }

end
```

Invoke `as_json`.

``` ruby
widget = Widget.first

# the `:short` version of the JSON, `gadgets` not included
widget.as_json

# equivalent to the above
widget.as_json(properties: :short)

# `:public` version of the JSON, `gadgets` returned with `:short` JSON, no `:extras`
widget.as_json(properties: :public)

# `:all` version of the JSON, `gadgets` returned with `:all` JSON, including `:extras`
widget.as_json(properties: :all)
```

Configuration
-------------

By default `Mongoid::CachedJson` will use an instance of `ActiveSupport::Cache::MemoryStore` in a non-Rails and `Rails.cache` in a Rails environment. You can configure it to use any other cache store.

``` ruby
Mongoid::CachedJson.configure do |config|
  config.cache = ActiveSupport::Cache::FileStore.new
end
```

The default JSON version returned from `as_json` is `:unspecified`. If you wish to redefine this, set `Mongoid::CachedJson.config.default_version`.

``` ruby
Mongoid::CachedJson.configure do |config|
  config.default_version = :v2
end
```

Defining Fields
---------------

`Mongoid::CachedJson` supports the following options:

* `:hide_as_child_json_when` is an optional function that omits the child key from `as_json` parent objects when it returns true, eg. `cached_json hide_as_child_json_when: lambda { |instance| ! instance.secret? }`. A missing relationship remains a `nil` value.

`Mongoid::CachedJson` field definitions support the following options:

* `:definition` can be a symbol or an anonymous function, eg. `description: { definition: :name }` or `description: { definition: lambda { |instance| instance.name } }`
* `:type` can be `:reference`, required for referenced objects
* `:properties` can be one of `:short`, `:public`, `:all`, in this order
* `:version` can be a single version for this field to appear in
* `:versions` can be an array of versions for this field to appear in
* `:reference_properties` can be one of `:short`, `:public`, `:all`, default will select the reference properties format dynamically (see below)

Reference Properties
--------------------

When calling `as_json` on a model that contains references to other models the value of the `:properties` option passed into the `as_json` call will be chosen as follows:

* Use the value of the `:reference_properties` option, if specified.
* For `:short` JSON, use `:short`.
* For `:public` JSON, use `:public`.
* For `:all` JSON, use `:all`.

The dynamic selection where `:public` generates `:short` references allows to return smaller embedded collections, while `:all` allows to fetch deep data. Another way of looking at this is to say that a field in a `:short` JSON appears in collections, a field declared in the `:public` JSON appears for all users and the field declared in the `:all` JSON appears for object owners only.

To override this behavior and always return the `:short` JSON for a child reference, use `:reference_properties`. In the following example we would want `Person.as_json(properties: :all)` to return the social security number for that person, but not for all their friends.

``` ruby
class Person
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  field :ssn
  has_and_belongs_to_many :friends, class_name: 'Person'

  json_fields \
    name: {},
    ssn: { properties: :all },
    friends: { properties: :public, reference_properties: :short }

end
```

Versioning
----------

You can set an optional `version` or `versions` attribute on JSON fields. Consider the following definition where the first version defined `:name`, then split it into `:first`, `:middle` and `:last` in version `:v2` and introduced a date of birth in `:v3`.

``` ruby
class Person
  include Mongoid::Document
  include Mongoid::CachedJson

  field :first
  field :last

  def name
    [ first, middle, last ].compact.join(' ')
  end

  json_fields \
    first: { versions: [ :v2, :v3 ] },
    last: { versions: [ :v2, :v3 ] },
    middle: { versions: [ :v2, :v3 ] },
    born: { versions: :v3 },
    name: { definition: :name }

end
```

``` ruby
person = Person.create(first: 'John', middle: 'F.', last: 'Kennedy', born: 'May 29, 1917')
person.as_json # { name: 'John F. Kennedy' }
person.as_json(version: :v2) # { first: 'John', middle: 'F.', last: 'Kennedy', name: 'John F. Kennedy' }
person.as_json(version: :v3) # { first: 'John', middle: 'F.', last: 'Kennedy', name: 'John F. Kennedy', born: 'May 29, 1917' }
```

Transformations
---------------

You can define global transformations on all JSON values with `Mongoid::CachedJson.config.transform`. Each transformation must return a value. In the following example we extend the JSON definition with an application-specific `:trusted` field and encode any content that is not trusted.

``` ruby
class Widget
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  field :description

  json_fields \
    name: { trusted: true },
    description: {}
end
```

``` ruby
  Mongoid::CachedJson.config.transform do |field, definition, value|
    trusted = !!definition[:trusted]
    trusted ? value : CGI.escapeHTML(value)
  end
```

Mixing with Standard as_json
----------------------------

Taking part in the `Mongoid::CachedJson` `json_fields` scheme is optional: you can still write `as_json` methods where it makes sense.

Turning Caching Off
-------------------

You can set `Mongoid::CachedJson.config.disable_caching = true`. It may be a good idea to set it to `ENV['DISABLE_JSON_CACHING']`, in case this turns out not to be The Solution To All Of Your Performance Problems (TM).

Cache Invalidation Boundaries
-----------------------------

Normal model updates and destroys expire that document's JSON fragments through Mongoid callbacks. Bulk or raw collection updates that bypass model callbacks cannot invalidate the cache automatically. Explicitly expire each affected document after such a write:

``` ruby
User.where(id: user_id).update_all(status: 'active')
User.find(user_id).expire_cached_json
```

Concurrent writes have a separate boundary: an older in-memory instance can repopulate a fragment after another instance has saved newer values and expired the cache. Reload stale instances before serializing them, and expire their fragments if a stale writer may already have repopulated the cache:

``` ruby
user.reload
user.expire_cached_json
user.as_json
```

Reloading and expiring are not an atomic cross-process operation. This gem does not provide a distributed revision or compare-and-set protocol for cache stores. Applications requiring strict consistency across concurrent writers should coordinate persistence and cache invalidation themselves or disable caching for the affected data.

Testing JSON
------------

This library overrides `as_json`, hence testing JSON results can be done at model level.

``` ruby
describe 'as_json' do
  before :each do
    @person = Person.create!(first: 'John', last: 'Doe')
  end
  it 'returns name' do
    expect(@person.as_json(properties: :public)[:name]).to eql 'John Doe'
  end
end
```

It's also common to test the results of the API using the [Pathy](https://github.com/twoism/pathy) library.

``` ruby
describe 'as_json' do
  before :each do
    person = Person.create!(first: 'John', last: 'Doe')
  end
  it 'returns name' do
    get "/api/person/#{person.id}"
    expect(response.body.at_json_path('name')).to eql 'John Doe'
  end
end
```

Testing Cache Invalidation
--------------------------

Cache is invalidated by calling `:expire_cached_json` on an instance.

``` ruby
describe 'updating a person' do
  before :each
    @person = Person.create!(name: 'John Doe')
  end
  it 'invalidates cache' do
    expect(@person).to receive(:expire_cached_json)
    @person.update_attributes!(name: 'updated')
  end
end
```
You may also want to use [this RSpec matcher](spec/support/matchers/invalidate.rb).

```ruby
describe 'updating a person' do
  it 'invalidates cache' do
    expect do
      @person.update_attributes!(name: 'updated')
    end.to invalidate @person
  end
end
```

Performance
-----------

This gem implements two interesting optimizations.

### Bulk Reference Resolving w/ Local Store

Consider an array of Mongoid instances, each with numerous references to other objects. It's typical to see such instances reference the same object. `Mongoid::CachedJson` first collects all JSON references, then resolves them after suppressing duplicates. This significantly reduces the number of cache queries.

### Fetching Cache Data in Bulk

Various cache stores, including Memcached, support bulk read operations. The [Dalli](https://github.com/mperham/dalli) gem exposes this via the `read_multi` method. `Mongoid::CachedJson` will always invoke `read_multi` where available, which significantly reduces the number of network roundtrips to the cache servers.

Contributing
------------

See [CONTRIBUTING](CONTRIBUTING.md).

Copyright and License
---------------------

MIT License, see [LICENSE](https://github.com/mongoid/mongoid-cached-json/blob/master/LICENSE.md) for details.

(c) 2012-2014 [Artsy](https://artsy.net) and [Contributors](CHANGELOG.md)
