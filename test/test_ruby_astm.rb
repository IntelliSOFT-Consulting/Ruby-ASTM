#ruby_astm_test.rb
require 'minitest/autorun'
require 'ruby_astm'

class TestRubyAstm < Minitest::Test

  def test_sysmex_550_receives_results
  	server = AstmServer.new("127.0.0.1",3000,nil)
  	$redis.del("patients")
  	root_path = File.dirname __dir__
  	sysmex_input_file_path = File.join root_path,'test','resources','sysmex_550_sample.txt'
  	server.process_text_file(sysmex_input_file_path)
  	assert_equal 1, $redis.llen("patients")
  end


  def test_em_200_receives_results
  	server = AstmServer.new("127.0.0.1",3000,nil)
  	$redis.del("patients")
  	root_path = File.dirname __dir__
  	em200_input_file_path = File.join root_path,'test','resources','em_200_sample.txt'
  	server.process_text_file(em200_input_file_path)
  	assert_equal 2, $redis.llen("patients")
  end

  def test_em_200_parses_query
  	server = AstmServer.new("127.0.0.1",3000,nil)
  	$redis.del("patients")
  	root_path = File.dirname __dir__
  	em200_input_file_path = File.join root_path,'test','resources','em_200_query_sample.txt'
  	server.process_text_file(em200_input_file_path)
  	assert_equal "010520182", server.headers[-1].queries[-1].sample_id
  end

  def test_pre_poll_LIS_no_existing_key
    poller = Poller.new
    $redis.flushall
    poller.pre_poll_LIS
    processing_status = JSON.parse($redis.get(Poller::POLL_STATUS_KEY))
    assert_equal Poller::RUNNING, processing_status[Poller::LAST_REQUEST_STATUS]
  end

  def test_pre_poll_LIS_running
    poller = Poller.new
    $redis.flushall
    poller.pre_poll_LIS
    processing_status = JSON.parse($redis.get(Poller::POLL_STATUS_KEY))
    assert_equal Poller::RUNNING, processing_status[Poller::LAST_REQUEST_STATUS]
    running_time = processing_status[Poller::LAST_REQUEST_AT]
    ## PRE POLL.
    poller.pre_poll_LIS
    processing_status = JSON.parse($redis.get(Poller::POLL_STATUS_KEY))
    assert_equal(running_time,processing_status[Poller::LAST_REQUEST_AT])
  end

  def test_pre_poll_LIS_expired_key
    poller = Poller.new
    $redis.flushall
    poller.pre_poll_LIS
    processing_status = JSON.parse($redis.get(Poller::POLL_STATUS_KEY))
    assert_equal Poller::RUNNING, processing_status[Poller::LAST_REQUEST_STATUS]
    expired_time = (Time.now - 10.years).to_i
    processing_status[Poller::LAST_REQUEST_AT] = (Time.now - 10.years).to_i
    $redis.set(Poller::POLL_STATUS_KEY,JSON.generate(processing_status))
    ## now pre poll again.
    ## the time should not be equal to processing time.
    poller.pre_poll_LIS
    processing_status = JSON.parse($redis.get(Poller::POLL_STATUS_KEY))
    assert_equal (processing_status[Poller::LAST_REQUEST_AT] == expired_time), false
  end

  def test_post_poll_LIS
    poller = Poller.new
    $redis.flushall
    poller.pre_poll_LIS
    processing_status = JSON.parse($redis.get(Poller::POLL_STATUS_KEY))
    assert_equal Poller::RUNNING, processing_status[Poller::LAST_REQUEST_STATUS]
    poller.post_poll_LIS
    processing_status = JSON.parse($redis.get(Poller::POLL_STATUS_KEY))
    assert_equal Poller::COMPLETED, processing_status[Poller::LAST_REQUEST_STATUS]
  end 

  def test_process_LIS_response
    poller = Poller.new
    $redis.del Poller::REQUISITIONS_SORTED_SET
    $redis.del Poller::REQUISITIONS_HASH
    ## here the only issue is that it is dependent, so we cannot test this like this. 
    lis_response = {
      "1543490233000" => [
        [nil, nil, nil, nil, nil, nil, nil, "HIV,HBS,ESR,GLUPP", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Lavender:barcode", "Serum:barcode", "Plasma:barcode", "Fluoride:barcode", "Urine:barcode", "ESR:barcode"]
      ]
    }
    poller.process_LIS_response(JSON.generate(lis_response))
    ## now assert redis.
    sorted_set = $redis.zrange Poller::REQUISITIONS_SORTED_SET, 0, -1, {withscores: true}
    assert_equal 1, sorted_set.size
    assert_equal 1543490233000.0, sorted_set[0][1]
    assert_equal [["{\"EDTA:Lavender:barcode\":[],\"SERUM:Serum:barcode\":[],\"PLASMA:Plasma:barcode\":[\"5\",\"4\"],\"FLUORIDE:Fluoride:barcode\":[\"GLUPP\"],\"URINE:Urine:barcode\":[],\"ESR:ESR:barcode\":[\"ESR\"]}", 1543490233000.0]], sorted_set
    requisitions_hash = $redis.hgetall Poller::REQUISITIONS_HASH
    assert_equal requisitions_hash, {"EDTA:Lavender:barcode"=>"[]", "SERUM:Serum:barcode"=>"[]", "PLASMA:Plasma:barcode"=>"[\"5\",\"4\"]", "FLUORIDE:Fluoride:barcode"=>"[\"GLUPP\"]", "URINE:Urine:barcode"=>"[]", "ESR:ESR:barcode"=>"[\"ESR\"]"}
    
  end

  ## kindly note, the credentials specified herein are no longer active ;)
  def test_initialized_google_lab_interface
    goog = Google_Lab_Interface.new(nil,"/home/bhargav/Desktop/credentials.json","/home/bhargav/Desktop/token.yaml","MNWKZC-L05-ufApJTSqaLq42yotVzKYhk")
    
  end 

  ## these two specs have to pass.
  def test_polls_for_requisitions_after_checkpoint
    poller = Poller.new
    $redis.del Poller::REQUISITIONS_SORTED_SET
    $redis.del Poller::REQUISITIONS_HASH
    ## here the only issue is that it is dependent, so we cannot test this like this. 
    lis_response = {
      "1543490233000" => [
        [nil, nil, nil, nil, nil, nil, nil, "HIV,HBS,ESR,GLUPP", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Lavender:barcode", "Serum:barcode", "Plasma:barcode", "Fluoride:barcode", "Urine:barcode", "ESR:barcode"]
      ],
      "1543490233001" => [
        [nil, nil, nil, nil, nil, nil, nil, "HIV,HBS,ESR,GLUPP", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Lavender:barcode", "Serum:barcode", "Plasma:barcode", "Fluoride:barcode", "Urine:barcode", "ESR:barcode"]
      ]
    }
    poller.process_LIS_response(JSON.generate(lis_response))
    checkpoint = poller.get_checkpoint
    assert_equal checkpoint, 1543490233001
  end

  def test_query_uses_requisitions_hash_to_generate_response
    server = AstmServer.new("127.0.0.1",3000,nil)
    $redis.del("patients")
    root_path = File.dirname __dir__
    em200_input_file_path = File.join root_path,'test','resources','em_200_query_sample.txt'
    ## add an entry for the id specified in the query.
    $redis.hset(Poller::REQUISITIONS_HASH,"010520182",JSON.generate(["GLUR"]))
    server.process_text_file(em200_input_file_path)
    tests = server.headers[-1].queries[-1].get_tests
    assert_equal tests, JSON.parse($redis.hget(Poller::REQUISITIONS_HASH,"010520182"))
  end
 
end