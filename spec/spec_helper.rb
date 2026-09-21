require "rbs_enum"

RbsEnum.sig_root = File.expand_path("fixtures", __dir__)

RSpec.configure do |config|
  config.before do
    RbsEnum.strict = false
    RbsEnum.clear_cache!
  end
end
