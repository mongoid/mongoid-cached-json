Next Release
------------

* Collect a JSON partial representation first, then fetch data from cache only once per-key - [@dblock](http://github.com/dblock), [@macreery](http://github.com/macreery).
* Use `read_multi` if the cache store supports it to fetch data from cache in bulk - [@dblock](http://github.com/dblock), [@macreery](http://github.com/macreery).

1.3 (11/12/2012)
----------------

* Removed requirement for `bson_ext`, support for Mongoid 3.0 - [@dblock](http://github.com/dblock).

1.2.3 (7/3/2012)
----------------

* Fix: including a `referenced_in` field in `json_fields` within a child `embedded_in` a parent causes an "access to the collection is not allowed since it is an embedded document" error - [@dblock](http://github.com/dblock).

1.2.2 (7/3/2012)

* Fix [#6](https://github.com/dblock/mongoid-cached-json/issues/6): including parent in `json_fields` within a polymorphic reference fails with an "uninitialized constant" error - [@dblock](http://github.com/dblock).

1.2.1 (6/12/2012)
-----------------

* Allow `nil` parameter in as_json - [@dblock](http://github.com/dblock).

1.2.0 (5/28/2012)
------------------

* Fix: cache key generation bug when using Mongoid 3 - [@marbemac](http://github.com/marbemac).

1.1.1 (3/21/2012)
-----------------

* Fix: caching/invalidating referenced polymorphic documents - [@macreery](http://github.com/macreery).

1.1 (2/29/2012)
---------------

* Added support for versioning - [@dblock](http://github.com/dblock).

1.0 (2/20/2012)
---------------

* Initial release - [@aaw](http://github.com/aaw).
* Retired support for `:markdown` in favor of `Mongoid::CachedJson::transform` - [@dblock](http://github.com/dblock).
* Added `Mongoid::CachedJson::configure` - [@dblock](http://github.com/dblock).
* Added support for `:markdown` - [@macreery](http://github.com/macreery).

