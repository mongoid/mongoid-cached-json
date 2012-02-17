Cached JSON
===========

Typical *as_json* definitions may involve lots of database point queries and method calls. When returning collections of objects, a single call may yield hundreds of database queries that can take seconds. This library mitigates the problem by implementing a module called *CachedJson*.

CachedJson enables returning mutliple JSON formats from a single class and provides some rules for returning embedded or referenced data. It then uses a scheme where fragments of JSON are cached for a particular (class, id) pair containing only the data that doesn't involve references/embedded documents. To get the full JSON for an instance, CachedJson will combine fragments of JSON from the instance with fragments representing the JSON for its references. In the best case, when all of these fragments are cached, this falls through to a few cache lookups followed by a couple Ruby hash merges to create the JSON.

CachedJson currently only works with the Mongoid ODM. We're looking forward to pull requests to enable ActiveRecord.

Quickstart
----------

Add `cached-json` to your Gemfile.

    gem "cached-json"

Include `CachedJson` in your models.

``` ruby
class Gadget
  include CachedJson

  field :name
  field :extras

  belongs_to :widget

  json_fields \
    name: { },
    extras: { properties: :public }

end

class Widget
  include CachedJson

  field :name
  has_many :gadgets

  json_fields \
    name: { },
    gadgets: { type: :reference, properties: :public }

end
```

Invoke `as_json`.

``` ruby
  Widget.first.as_json # the `:short` version of the JSON, `gadgets` not included
  Widget.first.as_json({properties: :short}) # equivalent to the above
  Widget.first.as_json({properties: :public}) # `:public` version of the JSON, `gadgets` returned with `:short` JSON, no `:extras`
  Widget.first.as_json({properties: :all}) # `:all` version of the JSON, `gadgets` returned with `:all` JSON, including `:extras`
```

Configuration
-------------

By default CachedJson will use an instance of `ActiveSupport::Cache::MemoryStore` in a non-Rails and `Rails.cache` in a Rails environment. You can configure it to use any other cache store.

``` ruby
CachedJson.configure do |config|
  config.cache = ActiveSupport::Cache::FileStore.new
end
```

Turning It Off
--------------

Taking part in the whole CachedJson optimization scheme is entirely optional: you can still write *as_json* methods where it makes sense. You can also set `ENV['DISABLE_JSON_CACHING']=true`, which switches all of this caching off entirely in case this turns out not to be The Solution To All Of Your Problems (TM).

Benchmarks
----------

The following benchmarks are anecdotal evidence. To collect these numbers CachedJson has been applied to one specific project.

First, how long does it take to pull 100 widgets back from the database?

    start = Time.now; Widget.all.take(100); Time.now - start
    => 0.293994069
    start = Time.now; Widget.all.take(100); Time.now - start
    => 0.173017952
    start = Time.now; Widget.all.take(100); Time.now - start
    => 0.056002937
    start = Time.now; Widget.all.take(100); Time.now - start
    => 0.307731487

Invoke `as_json` without JSON caching.

    start = Time.now; Widget.all.take(100).as_json({properties: :short}); Time.now - start
    => 4.945250191
    start = Time.now; Widget.all.take(100).as_json({properties: :short}); Time.now - start
    => 2.607833912
    start = Time.now; Widget.all.take(100).as_json({properties: :short}); Time.now - start
    => 2.744518664
    start = Time.now; Widget.all.take(100).as_json({properties: :short}); Time.now - start
    => 3.143353997

Invoke `as_json` with JSON caching.

    start = Time.now; Widget.all.take(100).as_json({properties: :short}); Time.now - start
    => 0.929413099
    start = Time.now; Widget.all.take(100).as_json({properties: :short}); Time.now - start
    => 0.995467915
    start = Time.now; Widget.all.take(100).as_json({properties: :short}); Time.now - start
    => 0.830720099
    start = Time.now; Widget.all.take(100).as_json({properties: :short}); Time.now - start
    => 0.914590311

Copyright and License
---------------------

MIT License, see [LICENSE](LICENSE.md) for details.

(c) 2012 Art.sy Inc. and [Contributors](CONTRIBUTORS.md)


