require 'rubygems'
require 'sinatra'
require 'google/api_client'

class Prediction < Sinatra::Base

	enable :sessions

	# FILL IN THIS SECTION
	# ------------------------
	# APP_NAME : application name
	# GOOGLE_STORAGE_BUCKET_NAME : This is the {bucket} name you are using
	# PREDICTION_DATA_OBJECT : This is the {object} name you are using
	# GOOGLE_CLIENT_EMAIL : Email of service account
	# GOOGLE_KEYFILE : Filename of the private key
	# GOOGLE_PASSPHRASE : Passphrase for private key
	# ------------------------

	configure do
	  client = Google::APIClient.new(application_name: ENV["APP_NAME"])

	  # Authorize service account
	  keyfile = Rails.root.join 'config', ENV["GOOGLE_KEYFILE"]
	  key = Google::APIClient::PKCS12.load_key(keyfile, ENV["GOOGLE_PASSPHRASE"])
	  asserter = Google::APIClient::JWTAsserter.new(
	     ENV["GOOGLE_CLIENT_EMAIL"],
	     'https://www.googleapis.com/auth/prediction',
	     key)
	  client.authorization = asserter.authorize()

	  prediction = client.discovered_api('prediction', 'v1.5')

	  set :api_client, client
	  set :prediction, prediction
	end

	def api_client; settings.api_client; end
	def prediction; settings.prediction; end

	get '/' do
	  erb :index
	end

	get '/train' do
	  training = prediction.trainedmodels.insert.request_schema.new
	  training.id = 'challengeinfo'
	  training.storage_data_location = File.join(ENV["GOOGLE_STORAGE_BUCKET_NAME"], ENV["PREDICTION_DATA_OBJECT"])
	  result = api_client.execute(
	    :api_method => prediction.trainedmodels.insert,
	    :headers => {'Content-Type' => 'application/json'},
	    :body_object => training
	  )

	  return [
	    200,
	    [["Content-Type", "application/json"]],
	    ::JSON.generate({"status" => "success"})
	  ]
	end

	get '/checkStatus' do
	  result = api_client.execute(
	    :api_method => prediction.trainedmodels.get,
	    :parameters => {'id' => 'challengeinfo'}
	  )

	  return [
	    200,
	    [["Content-Type", "application/json"]],
	    assemble_json_body(result)
	  ]
	end

	post '/predict' do
		puts params.inspect
	  input = prediction.trainedmodels.predict.request_schema.new
	  input.input = {}
	  input.input.csv_instance = [
	  	params["platforms"],
	  	params["technologies"],
	  	params["submitters"],
	  	params["total_prize"],
	  	params["top_prize"],
	  	params["challenge_length"]
	 	]
	  result = api_client.execute(
	    :api_method => prediction.trainedmodels.predict,
	    :parameters => {'id' => 'challengeinfo'},
	    :headers => {'Content-Type' => 'application/json'},
	    :body_object => input
	  )

	  puts result.inspect

	  return [
	    200,
	    [["Content-Type", "application/json"]],
	    assemble_json_body(result)
	  ]
	end

	def assemble_json_body(result)
	  # Assemble some JSON our client-side code can work with.
	  json = {}
	  if result.status != 200
	    if result.data["error"]
	      message = result.data["error"]["errors"].first["message"]
	      json["message"] = "#{message} [#{result.status}]"
	    else
	      json["message"] = "Error. [#{result.status}]"
	    end
	    json["response"] = ::JSON.parse(result.body)
	    json["status"] = "error"
	  else
	    json["response"] = ::JSON.parse(result.body)
	    json["status"] = "success"
	  end
	  return ::JSON.generate(json)
	end

end