require 'csv'
class UploadsController < ApplicationController
	def index
		@upload = Upload.new
		@challenge_participants = (DB[:challenge_participants] if DB.table_exists?(:challenge_participants)) || []
		@challenges = (DB[:challenges] if DB.table_exists?(:challenges))  || []
    @challenge_platforms = (DB[:challenge_platforms] if DB.table_exists?(:challenge_platforms))  || []
		@challenge_technologies = (DB[:challenge_technologies] if DB.table_exists?(:challenge_technologies))  || []
	end

  def challenge_platforms
    data = CSV.new params[:upload][:data].tempfile
    PredictionData.import_challenge_platforms(data.to_hash)
    redirect_to uploads_path
  end

  def challenge_technologies
		data = CSV.new params[:upload][:data].tempfile
  	PredictionData.import_challenge_technologies(data.to_hash)
  	redirect_to uploads_path
  end

  def challlenges
		data = CSV.new params[:upload][:data].tempfile
  	PredictionData.import_challenges(data.to_hash)
  	redirect_to uploads_path
  end

  def challenge_participants
		data = CSV.new params[:upload][:data].tempfile
  	PredictionData.import_challenge_participants(data.to_hash)
  	redirect_to uploads_path, notice: 'Upload completed'
  end

  def generate_prediction_data
    # drop it like it's hot
    PredictionData.delete_all
    PredictionData.generate
  	send_data PredictionData.to_csv, filename: 'prediction_data.csv'
  end
end

class CSV
	def to_hash
		headers = self.shift.map {|i| i.to_s }
		string_data = self.map {|row| row.map {|cell| cell.to_s } }
		array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten] }
	end
end