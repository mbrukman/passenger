require 'support/config'
require 'support/test_helper'
require 'phusion_passenger/wsgi/application_spawner'
require 'phusion_passenger/utils'
require 'fileutils'
require 'tempfile'

describe PhusionPassenger::WSGI::ApplicationSpawner do
	include TestHelper
	include PhusionPassenger::Utils
	
	before :each do
		ENV['PHUSION_PASSENGER_TMP'] = "#{Dir.tmpdir}/wsgi_test.tmp"
		@stub = setup_stub('wsgi')
		File.unlink("#{@stub.app_root}/passenger_wsgi.pyc") rescue nil
	end
	
	after :each do
		@stub.destroy
		ENV.delete('PHUSION_PASSENGER_TMP')
		FileUtils.rm_rf("wsgi_test.tmp")
	end
	
	it "can spawn our stub application" do
		spawn(@stub.app_root).close
	end
	
	it "creates a socket in Phusion Passenger's temp directory" do
		begin
			app = spawn(@stub.app_root)
			Dir["#{passenger_tmpdir}/passenger_wsgi.*"].should have(1).item
		ensure
			app.close rescue nil
		end
	end
	
	specify "the backend process deletes its socket upon termination" do
		spawn(@stub.app_root).close
		sleep 0.2 # Give it some time to terminate.
		Dir["#{passenger_tmpdir}/passenger_wsgi.*"].should be_empty
	end
	
	def spawn(app_root)
		PhusionPassenger::WSGI::ApplicationSpawner.spawn_application(app_root,
			true, CONFIG['lowest_user'])
	end
end

