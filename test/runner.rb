#require '/home/bhargav/Github/Ruby-ASTM/lib/ruby_astm.rb'
#require 'ruby_astm.rb'
server = AstmServer.new({:server_ip => "127.0.0.1", :server_port => 3000},[],nil,nil,{:use_mappings => false, :log => true, :log_output_directory => "/home/bhargav/Desktop", :output_options => {"format" => "csv", "records_per_file" => "single", "output_directory" => "/home/bhargav/Desktop"}})

server.start_server
