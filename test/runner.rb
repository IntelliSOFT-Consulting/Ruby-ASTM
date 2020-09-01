require '/home/bhargav/Github/Ruby-ASTM/lib/ruby_astm.rb'

ethernet_connections = [{:server_ip => "127.0.0.1", :server_port => 3000}]
server = AstmServer.new(ethernet_connections,[],nil,nil,{:use_mappings => false, :log => true, :log_output_directory => "/home/bhargav/Desktop", :output_options => {"format" => LabInterface::CSV, "records_per_file" => "single", "output_directory" => "/home/bhargav/Desktop"}})
server.start_server