# Upgrading

## Upgrading to 1.7.0

### Hidden child references

[#35](https://github.com/mongoid/mongoid-cached-json/pull/35) changes how a single child reference is serialized when the child's `hide_as_child_json_when` predicate returns `true`. Previously, an existing but hidden child and a missing child both appeared as `child: nil` (`"child": null` in JSON), so clients could not distinguish them. Now, an existing but hidden child's key is omitted; a missing child still appears as `child: nil`.

Here, `parent` is a `SecretParent` document with a `has_one` relationship to a `SometimesSecret` document. The parent exposes that relationship as the JSON field `child`; the hiding predicate is defined on the child model:

```ruby
class SecretParent
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  has_one :sometimes_secret

  json_fields \
    name: {},
    child: { definition: :sometimes_secret, type: :reference }
end

class SometimesSecret
  include Mongoid::Document
  include Mongoid::CachedJson

  field :secret
  field :should_tell_secret, type: Boolean
  belongs_to :secret_parent

  json_fields \
    hide_as_child_json_when: lambda { |child| !child.should_tell_secret },
    secret: {}
end

parent = SecretParent.create!(name: 'Parent')
parent.create_sometimes_secret!(secret: 'Afraid of the dark', should_tell_secret: false)

# The child exists, but its hiding predicate returns true.
# Before 1.7.0:
parent.as_json(properties: :short)
# => { name: 'Parent', child: nil }

# From 1.7.0:
parent.as_json(properties: :short)
# => { name: 'Parent' }

# By contrast, a parent with no child still includes an explicit nil.
parent_without_child = SecretParent.create!(name: 'No child')
parent_without_child.as_json(properties: :short)
# => { name: 'No child', child: nil }
```

A genuinely missing relationship still includes `child: nil`. Requests using `properties: :all` and serialization of the child itself are unchanged.

Update clients and response schemas that require the child key to allow its absence. In Ruby, `json[:child]` still returns `nil` for either case; use `json.key?(:child)` to distinguish an omitted key from an explicit `nil`.

Invalidate existing cached JSON fragments when deploying this change so cached results use the new representation. If the cache is shared with other applications, invalidate only this application's cached JSON entries rather than clearing the entire store.
