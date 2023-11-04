module Standby
  VERSION = '4.0.0'

  class << self
    def version_gte?(version)
      Gem::Version.new(ActiveRecord.version) >= Gem::Version.new(version)
    end
  end
end
