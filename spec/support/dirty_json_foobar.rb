class DirtyJsonFoobar < JsonFoobar
  
  field :dirty_foo
  field :ignored_foo
  
  json_fields \
    dirty_foo: { properties: :public, markdown: true },
    ignored_foo: { properties: :public }

end

