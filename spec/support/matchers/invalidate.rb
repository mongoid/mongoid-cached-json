RSpec::Matchers.define :invalidate do |target|
  supports_block_expectations

  match do |block|
    call_counts = 0
    Array(target).each do |cached_model|
      allow(cached_model).to receive(:expire_cached_json) do
        call_counts += 1
      end
    end
    block.call if block.is_a?(Proc)
    call_counts == Array(target).count
  end

  failure_message do
    'target cache to be invalidated, but it was not'
  end

  failure_message_when_negated do
    'target cache to be invalidated, but it was not'
  end
end
