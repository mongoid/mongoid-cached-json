1.5.3 (2015/09/17)
------------------

* Compatibility with Mongoid 5 - [@dblock](http://github.com/dblock).

1.5.2 (2014/29/12)
------------------

* Fixed support for Ruby 2.2.0 - [@dblock](http://github.com/dblock).
* Implemented RuboCop, Ruby-style linter - [@dblock](http://github.com/dblock).
* Upgraded to RSpec 3.1 - [@dblock](http://github.com/dblock).
* Removed Jeweler - [@dblock](http://github.com/dblock).

1.5.1 (2013/05/07)
--------------------

* Fixed `read_multi` calls so as to enable proper cache reading behavior in stores other than `ActiveSupport::Cache::DalliStore` - [@macreery](http://github.com/macreery).

1.5 (2013/04/13)
----------------

* Added `:reference_properties` that disables dynamic selection of the type of JSON to return for a reference - [@dblock](https://github.com/dblock).

1.4.3 (2013/01/25)
------------------

* For caches that support `read_multi`, do not attempt to fetch JSON a second time via `fetch`, write it directly to cache - [@dblock](https://github.com/dblock).

1.4.2 (2013/01/24)
------------------

* Fix: calling `as_json` on a destroyed Mongoid 3.1 object with a HABTM relationship raises `undefined method 'map' for nil:NilClass` - [@dblock](http://github.com/dblock).

1.4.1 (2013/01/22)
------------------

* Invalidate cache in `after_destroy` - [@dblock](http://github.com/dblock).
* Do not invalidate cache when the document is created - [@dblock](http://github.com/dblock).
* Invalidate cache in `after_update` instead of `before_update` - [@dblock](http://github.com/dblock).

1.4 (2013/01/20)
---------------

* Collect a JSON partial representation first, then fetch data from cache only once per-key - [@dblock](http://github.com/dblock), [@macreery](http://github.com/macreery).
* Use `read_multi` if the cache store supports it to fetch data from cache in bulk - [@dblock](http://github.com/dblock), [@macreery](http://github.com/macreery).
* Added a benchmark test suite - [@dblock](http://github.com/dblock), [@macreery](http://github.com/macreery).

1.3 (2012/11/12)
----------------

* Removed requirement for `bson_ext`, support for Mongoid 3.0 - [@dblock](http://github.com/dblock).

1.2.3 (2012/07/03)
------------------

* Fix: including a `referenced_in` field in `json_fields` within a child `embedded_in` a parent causes an "access to the collection is not allowed since it is an embedded document" error - [@dblock](http://github.com/dblock).

1.2.2 (2012/07/03)
------------------

* Fix [#6](https://github.com/dblock/mongoid-cached-json/issues/6): including parent in `json_fields` within a polymorphic reference fails with an "uninitialized constant" error - [@dblock](http://github.com/dblock).

1.2.1 (2012/06/12)
------------------

* Allow `nil` parameter in as_json - [@dblock](http://github.com/dblock).

1.2.0 (2012/05/28)
------------------

* Fix: cache key generation bug when using Mongoid 3 - [@marbemac](http://github.com/marbemac).

1.1.1 (2012/03/21)
------------------

* Fix: caching/invalidating referenced polymorphic documents - [@macreery](http://github.com/macreery).

1.1 (2012/02/29)
----------------

* Added support for versioning - [@dblock](http://github.com/dblock).

1.0 (2012/02/20)
----------------

* Initial release - [@aaw](http://github.com/aaw).
* Retired support for `:markdown` in favor of `Mongoid::CachedJson::transform` - [@dblock](http://github.com/dblock).
* Added `Mongoid::CachedJson::configure` - [@dblock](http://github.com/dblock).
* Added support for `:markdown` - [@macreery](http://github.com/macreery).

