$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'quickbooks'
require 'rbconfig'

MS_WINDOWS = Config::CONFIG['host_os'] =~ /mswin|mingw/ unless defined?(MS_WINDOWS)

if MS_WINDOWS
  test_file = File.join(File.dirname(File.expand_path(__FILE__)), 'test.qbw')
  test_file.gsub!('/','\\')

  unless File.exists?(test_file)
    puts "To run these specs, create a new company called test and save it"
    puts "as: #{test_file}"
    exit
  end

  Quickbooks::Base.setup(
    :support_simple_start => true,
    :file                 => test_file,
    :application_name     => "quickbooks gem specs",
    :unattended_mode      => true,
    :personal_data        => :not_needed
  )
else
  puts "WARNING: skipping all tests that can only be run on MS Windows"
end