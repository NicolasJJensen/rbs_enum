require "rails/railtie"

module RbsEnum
  class Railtie < ::Rails::Railtie
    initializer "rbs_enum.configure" do |app|
      RbsEnum.sig_root ||= app.root.join("sig")
    end

    config.to_prepare { RbsEnum.clear_cache! }
  end
end
