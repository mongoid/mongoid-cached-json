Next Release
------------

* Collect a JSON partial representation first, then fetch data from cache only once per-key, [Daniel Doubrovkine](http://github.com/dblock).

1.3 (11/12/2012)
----------------

* Removed requirement for `bson_ext`, support for Mongoid 3.0, [Daniel Doubrovkine](http://github.com/dblock).

1.2.3 (7/3/2012)
----------------

* Fix: including a `referenced_in` field in `json_fields` within a child `embedded_in` a parent causes an "access to the collection is not allowed since it is an embedded document" error, [Daniel Doubrovkine](http://github.com/dblock).

1.2.2 (7/3/2012)

* Fix [#6](https://github.com/dblock/mongoid-cached-json/issues/6): including parent in `json_fields` within a polymorphic reference fails with an "uninitialized constant" error, [Daniel Doubrovkine](http://github.com/dblock).

1.2.1 (6/12/2012)
-----------------

* Allow `nil` parameter in as_json, [Daniel Doubrovkine](http://github.com/dblock).

1.2.0 (5/28/2012)
------------------

* Fix: cache key generation bug when using Mongoid 3, [Marc MacLeod](http://github.com/marbemac).

1.1.1 (3/21/2012)
-----------------

* Fix: caching/invalidating referenced polymorphic documents, [Frank Macreery](http://github.com/macreery).

1.1 (2/29/2012)
---------------

* Added support for versioning, [Daniel Doubrovkine](http://github.com/dblock).

1.0 (2/20/2012)
---------------

* Initial release, [Aaron Windsor](http://github.com/aaw).
* Retired support for `:markdown` in favor of `Mongoid::CachedJson::transform`, [Daniel Doubrovkine](http://github.com/dblock).
* Added `Mongoid::CachedJson::configure`, [Daniel Doubrovkine](http://github.com/dblock).
* Added support for `:markdown`, [Frank Macreery](http://github.com/macreery).

