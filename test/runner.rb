# to run this file
# do 
# bundle exec ruby runner.rb
require '../lib/ruby_astm.rb'

server = AstmServer.new([{:server_ip => "127.0.0.1", :server_port => 3000}],[],nil,nil,{:use_mappings => false, :log => true, :log_output_directory => "/home/bhargav/Github/Ruby-ASTM/output_files", :output_options => {"format" => "csv", "records_per_file" => "single", "output_directory" => "/home/bhargav/Github/Ruby-ASTM/output_files"}})

server.start_server

