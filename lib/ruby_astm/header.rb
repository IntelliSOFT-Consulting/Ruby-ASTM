class Header
	attr_accessor :machine_name
	attr_accessor :patients
	attr_accessor :queries
	attr_accessor :response_sent
	attr_accessor :protocol

	def is_astm?
		self.protocol == "ASTM"
	end		

	def is_hl7?
		self.protocol == "HL7"
	end


	def set_protocol(args)
		self.protocol = "ASTM"
	end	

	def initialize(args={})
		self.patients = []
		self.queries = []
		self.response_sent = false
		self.machine_name = ""
		if line = args[:line]
			set_machine_name(args)
			set_protocol(args)
		end
	end

	def set_machine_name(args)
		if line = args[:line]
			unless line.fields[4].empty?
				fields = line.fields[4].split(/\^/)
				self.machine_name = fields[0].strip
			end
		end
	end

	## while committing to csv, it will use the following format
	## machine_name + "_" + current_time + "_" + patient_id.csv	
	def commit(args)
		#puts "COMMITTING HEADERS -----------> #{args}:"
		#puts args.to_s
		if args[:output_options]["format"] == LabInterface::REDIS
		
			self.patients.map{|patient| $redis.lpush("patients",patient.to_json)}

		elsif args[:output_options]["format"] == LabInterface::CSV
			
			args[:output_options]["records_per_file"] ||= "single"

			if args[:output_options]["records_per_file"] ==  "single"

				self.patients.each do |patient|
					csv_file_name = self.machine_name + "_" + Time.now.strftime('%d %B %Y %I:%M:%S %P').to_s + "#{patient.patient_id}.csv"
					csv_file_path = args[:output_options]["output_directory"] + "/" + csv_file_name
					
					patient_csv_data = patient.to_csv

					patient_csv_data[:column_names].unshift("Time")
					patient_csv_data[:column_values].unshift(Time.now.strftime('%d %B %Y %I:%M:%S %P'))

					patient_csv_data[:column_names].unshift("Machine Id")
					patient_csv_data[:column_values].unshift(self.machine_name)
					
					IO.write(csv_file_path,(patient_csv_data[:column_names].join(",") + "\n" + patient_csv_data[:column_values].join(",")))
					
				end
				
			end 

		else
			puts "no known output format has been provided! PLEASE PROVIDE AN OUTPUT FORMAT"
		end

		#puts JSON.pretty_generate(JSON.parse(self.to_json))
	end

	def get_header_response(options)
		if (options[:machine_name] && (options[:machine_name] == "cobas-e411"))
			"1H|\\^&|||host^1|||||cobas-e411|TSDWN^REPLY|P|1\r"
		else
			"1H|\`^&||||||||||P|E 1394-97|#{Time.now.strftime("%Y%m%d%H%M%S")}\r"
		end
	end

	## depends on the machine code.
	## if we have that or not.
	def build_one_response(options)
		##puts "building one response=========="
		##puts "queries are:"
		##puts self.queries.size.to_s
		responses = []
		self.queries.each do |query|
			#puts "doing query"
			#puts query.sample_ids
			header_response = get_header_response(options)
			query.build_response(options).each do |qresponse|
				#puts "qresponse is:"
				#puts qresponse
				header_response += qresponse
			end
			responses << header_response
		end
		responses
	end

	## used to respond to queries.
	## @return[String] response_to_query : response to the header query.
	def build_responses
		responses = []
		self.queries.each do |query|
			header_response = "1H|\`^&||||||||||P|E 1394-97|#{Time.now.strftime("%Y%m%d%H%M%S")}\r"
			query.build_response.each do |qresponse|
				responses << (header_response + qresponse)
			end
		end
=begin
		responses = self.queries.map {|query|
			header_response = "1H|\`^&||||||||||P|E 1394-97|#{Time.now.strftime("%Y%m%d%H%M%S")}\r"
			## here the queries have multiple responses.
			query.build_response.each do |qresponse|

			end
			query.response = header_response + query.build_response
			query.response
		}
=end
		responses
	end

	def to_json(args={})
        hash = {}
        self.instance_variables.each do |x|
            hash[x] = self.instance_variable_get x
        end
        return hash.to_json
    end

end