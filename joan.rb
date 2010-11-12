# Usage: $ ruby joan.rb [num iterations]
require 'net/http'	

class Bot
	URL = URI.parse('http://jabberwacky.icogno.com/webserviceform-joan')
	
	def initialize(name)
		@name = name
	end
	
	def respond(message = nil)
		@data.nil? ? start_conversation : post(message)
		
		response = @data["ttsText"]
		puts "#{@name}: #{response}"
		STDOUT.flush
		response
	end
	
	private
	
		def post(message)
			@data['STIMULUS'] = message
			@data['sub']	= 'Say'
			get_response { Net::HTTP.post_form(URL, @data) }
		end

		def start_conversation
			get_response { Net::HTTP.get_response(URL) }
		end
		
		# Retrieve all the variables and setup as a hash for doing a POST 
		def get_post_variables
			@data = {}
			@response_text.scan(/NAME=(\w+) TYPE=hidden VALUE="([^"]*)/) do |name, value|
				@data[name] = value
			end
		end
	
		def get_response
			trials = 3 # Try three times -- sometimes calls fail
			response = begin
				yield
			rescue
				trials -= 1
				trials > 0 ? retry : raise("Did not receive response after three attempts")
			end
			@response_text = response.body
			get_post_variables
		end
end

bots = %w{perl ruby }.map { |name| Bot.new(name) }

last_message = nil
(ARGV[0] || 10).to_i.times do
	bots.each { |bot| last_message = bot.respond(last_message) }
end
