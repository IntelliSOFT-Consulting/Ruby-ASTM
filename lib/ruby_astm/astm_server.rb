require 'rubygems'
require 'eventmachine'
#require 'em-rubyserial'
require "active_support/all"
require "json"
require "redis"
require "rest-firebase"
class AstmServer

	include LabInterface

	def initialize(ethernet_connections,serial_connections,mpg=nil,respond_to_queries=nil,options=nil)
		$redis = nil
		#$redis = Redis.new
		#self.class.log("Initializing AstmServer")
		self.ethernet_connections = ethernet_connections
		self.serial_connections = serial_connections
		self.server_ip = server_ip || "127.0.0.1"
		self.server_port = server_port || 3000
		self.respond_to_queries = respond_to_queries
		self.serial_port = serial_port
		self.serial_baud = serial_baud
		self.serial_parity = serial_parity
		self.usb_port = usb_port
		self.usb_baud = usb_baud
		self.usb_parity = usb_parity
		self.parse_options(options || {})
		$mappings = JSON.parse(IO.read(mpg || self.class.default_mappings))
	end

	def parse_options(options)
		#puts "options are:"
		#puts options.to_s
		self.query_class = options[:query_class] unless options[:query_class].blank?
			
		## the default output format.
		## default is redis., meaning it will output to redis.
		## if set to other formats, you are expected to provide the required options.
		## for eg: if set to csv, you must provide 
		self.output_options = options[:output_options] || {"format" => REDIS}

		if self.output_options["format"] == CSV
			## check if a csv output folder path has been provided.
			raise "please provide a valid directory for the csv files to be output into" if self.output_options["output_directory"].blank?
		end
			
		## whether to use the mappings to convert the machine codes to lis codes, if set to false, then it will output results in the same codes as sent by the machine.
		#puts "options are"
		#puts options.to_s
		#exit(1)
		if options[:use_mappings].nil?
			self.use_mappings = true
		else
			self.use_mappings = options[:use_mappings]
		end

		if options[:log].nil?
			self.log = false
		else
			self.log = options[:log]
			self.log_output_directory = options[:log_output_directory]
		end

		#puts "log becomes:"
		#puts self.log.to_s
		#puts self.log_output_directory.to_s

	end

	def start_server
		EventMachine.run {
			self.ethernet_connections.each do |econn|
				raise "please provide a valid ethernet configuration with ip address" unless econn[:server_ip]
				raise "please provide a valid ethernet configuration with port" unless econn[:server_port]
				EventMachine::start_server econn[:server_ip], econn[:server_port], LabInterface
				puts "running ASTM server on #{econn}"
				#self.class.log("Running ETHERNET  with configuration #{econn}")
			end

		}
	end	

end
