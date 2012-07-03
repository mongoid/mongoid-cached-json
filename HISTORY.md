1.2.2 (7/3/2012)
----------------

* Fix: including parent in `as_json` within a polymorphic reference fails with an "uninitialized constant" error, [Daniel Doubrovkine](http://github.com/dblock).

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

