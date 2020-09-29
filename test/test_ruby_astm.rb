#ruby_astm_test.rb
require 'minitest/autorun'
require 'ruby_astm'

class TestRubyAstm < Minitest::Test

  def setup
    $redis = Redis.new
    $redis.flushall
  end

  
  def test_xn_500_csv_output
    ethernet_connections = [{:server_ip => "127.0.0.1", :server_port => 3000}]
    server = AstmServer.new(ethernet_connections,[],nil,nil,{:use_mappings => false, :log => true, :log_output_directory => "/home/bhargav/Github/Ruby-ASTM/output_files", :output_options => {"format" => LabInterface::CSV, "records_per_file" => "single", "output_directory" => "/home/bhargav/Github/Ruby-ASTM/output_files"}})
    #$redis.del("patients")
    root_path = File.dirname __dir__
    input_file_path = File.join root_path,'test','resources','sysmex_550_sample.txt'
    k = IO.read(input_file_path)
   
    server.process_bytes(k.bytes)
   
  end

  def test_xp_300_csv_output
    ethernet_connections = [{:server_ip => "127.0.0.1", :server_port => 3000}]
    server = AstmServer.new(ethernet_connections,[],nil,nil,{:use_mappings => false, :log => true, :log_output_directory => "/home/bhargav/Github/Ruby-ASTM/output_files", :output_options => {"format" => LabInterface::CSV, "records_per_file" => "single", "output_directory" => "/home/bhargav/Github/Ruby-ASTM/output_files"}})
    #$redis.del("patients")
    root_path = File.dirname __dir__
    input_file_path = File.join root_path,'test','resources','sysmex_xp_300_sample.txt'
    k = IO.read(input_file_path)
   
    server.process_bytes(k.bytes)
   
  end


end