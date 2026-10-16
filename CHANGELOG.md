### 1.7.0 (Next)

* Your contribution here.
* [#33](https://github.com/mongoid/mongoid-cached-json/pull/33): Allow per-model cache bypass with `json_fields disable_caching: true` - [@dblock](https://github.com/dblock).
* [#31](https://github.com/mongoid/mongoid-cached-json/pull/31): Add explicit per-model schema cache versions, independent of API versions - [@dblock](https://github.com/dblock).
* [#39](https://github.com/mongoid/mongoid-cached-json/pull/39): Check pull request changelogs with Danger and report results in PR comments - [@dblock](https://github.com/dblock).
* [#34](https://github.com/mongoid/mongoid-cached-json/pull/34): Support `cache: false` on individual JSON fields - [@dblock](https://github.com/dblock).
* [#36](https://github.com/mongoid/mongoid-cached-json/pull/36): Document cache invalidation boundaries for callback-bypassing and concurrent writes - [@dblock](https://github.com/dblock).
* [#35](https://github.com/mongoid/mongoid-cached-json/pull/35): Omit hidden child references while preserving `nil` for missing references (see [UPGRADING](UPGRADING.md) for migration notes) - [@dblock](https://github.com/dblock).
* [#38](https://github.com/mongoid/mongoid-cached-json/pull/38): Fix a `:reference` field returning `nil` instead of `false` when its definition evaluates to a false-y, non-nil value - [@mzikherman](https://github.com/mzikherman).
* [#30](https://github.com/mongoid/mongoid-cached-json/pull/30): Replace the obsolete quality badge with Coveralls, generate real SimpleCov coverage in one modern CI job, and scope badges to upstream master - [@dblock](https://github.com/dblock).
* [#30](https://github.com/mongoid/mongoid-cached-json/pull/30): Modernize CI with GitHub Actions, testing representative Ruby/Mongoid/MongoDB combinations through Ruby 4.0, Mongoid 9, and MongoDB Server 8.0, with modern memcached cache integration - [@dblock](https://github.com/dblock).

### 1.6.0 (2019/05/31)

* [#20](https://github.com/mongoid/mongoid-cached-json/pull/20): Compatibility with Ruby 2.3, 2.4, 2.5 and 2.6 - [@yuki24](https://github.com/yuki24).
* [#20](https://github.com/mongoid/mongoid-cached-json/pull/20): Compatibility with Mongoid 6 - [@yuki24](https://github.com/yuki24).
* [#20](https://github.com/mongoid/mongoid-cached-json/pull/20): No longer test against Ruby 1.9.3 - [@yuki24](https://github.com/yuki24).
* [#22](https://github.com/mongoid/mongoid-cached-json/pull/22): Compatibility with Mongoid 7 - [@yuki24](https://github.com/yuki24).

### 1.5.3 (2015/09/17)

* Compatibility with Mongoid 5 - [@dblock](https://github.com/dblock).

### 1.5.2 (2014/12/29)

* Fixed support for Ruby 2.2.0 - [@dblock](https://github.com/dblock).
* Implemented RuboCop, Ruby-style linter - [@dblock](https://github.com/dblock).
* Upgraded to RSpec 3.1 - [@dblock](https://github.com/dblock).
* Removed Jeweler - [@dblock](https://github.com/dblock).

### 1.5.1 (2013/05/07)

* Fixed `read_multi` calls so as to enable proper cache reading behavior in stores other than `ActiveSupport::Cache::DalliStore` - [@macreery](https://github.com/macreery).

### 1.5.0 (2013/04/13)

* Added `:reference_properties` that disables dynamic selection of the type of JSON to return for a reference - [@dblock](https://github.com/dblock).

### 1.4.3 (2013/01/25)

* For caches that support `read_multi`, do not attempt to fetch JSON a second time via `fetch`, write it directly to cache - [@dblock](https://github.com/dblock).

### 1.4.2 (2013/01/24)

* Fix: calling `as_json` on a destroyed Mongoid 3.1 object with a HABTM relationship raises `undefined method 'map' for nil:NilClass` - [@dblock](https://github.com/dblock).

### 1.4.1 (2013/01/22)

* Invalidate cache in `after_destroy` - [@dblock](https://github.com/dblock).
* Do not invalidate cache when the document is created - [@dblock](https://github.com/dblock).
* Invalidate cache in `after_update` instead of `before_update` - [@dblock](https://github.com/dblock).

### 1.4.0 (2013/01/20)

* Collect a JSON partial representation first, then fetch data from cache only once per-key - [@dblock](https://github.com/dblock), [@macreery](https://github.com/macreery).
* Use `read_multi` if the cache store supports it to fetch data from cache in bulk - [@dblock](https://github.com/dblock), [@macreery](https://github.com/macreery).
* Added a benchmark test suite - [@dblock](https://github.com/dblock), [@macreery](https://github.com/macreery).

### 1.3.0 (2012/11/12)

* Removed requirement for `bson_ext`, support for Mongoid 3.0 - [@dblock](https://github.com/dblock).

### 1.2.3 (2012/07/03)

* Fix: including a `referenced_in` field in `json_fields` within a child `embedded_in` a parent causes an "access to the collection is not allowed since it is an embedded document" error - [@dblock](https://github.com/dblock).

### 1.2.2 (2012/07/03)

* Fix [#6](https://github.com/mongoid/mongoid-cached-json/issues/6): including parent in `json_fields` within a polymorphic reference fails with an "uninitialized constant" error - [@dblock](https://github.com/dblock).

### 1.2.1 (2012/06/12)

* Allow `nil` parameter in as_json - [@dblock](https://github.com/dblock).

### 1.2.0 (2012/05/28)

* Fix: cache key generation bug when using Mongoid 3 - [@marbemac](https://github.com/marbemac).

### 1.1.1 (2012/03/21)

* Fix: caching/invalidating referenced polymorphic documents - [@macreery](https://github.com/macreery).

### 1.1.0 (2012/02/29)

* Added support for versioning - [@dblock](https://github.com/dblock).

### 1.0.0 (2012/02/20)

* Initial release - [@aaw](https://github.com/aaw).
* Retired support for `:markdown` in favor of `Mongoid::CachedJson::transform` - [@dblock](https://github.com/dblock).
* Added `Mongoid::CachedJson::configure` - [@dblock](https://github.com/dblock).
* Added support for `:markdown` - [@macreery](https://github.com/macreery).
