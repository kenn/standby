module Slavery
  if defined? Rails::Railtie
  	class Railtie < Rails::Railtie
  	  initializer 'slavery.insert_into_active_record' do |app|
  	    ActiveSupport.on_load :active_record do
  	      include Slavery
  	    end
  	  end
  	end
  end
end
