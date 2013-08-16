class UploadsController < ApplicationController
	def index
		@upload = Upload.new
		@challenge_participants = PredictionData.session[:challenge_participants].find
		@challenges = PredictionData.session[:challenges].find
    @challenge_platforms = PredictionData.session[:challenge_platforms].find
		@challenge_technologies = PredictionData.session[:challenge_technologies].find
	end

  def challenge_platforms
    data = HashableCSV.new params[:upload][:data].tempfile
    PredictionData.import_challenge_platforms(data.to_hash)
    redirect_to uploads_path
  end

  def challenge_technologies
		data = HashableCSV.new params[:upload][:data].tempfile
  	PredictionData.import_challenge_technologies(data.to_hash)
  	redirect_to uploads_path
  end

  def challlenges
		data = HashableCSV.new params[:upload][:data].tempfile
  	PredictionData.import_challenges(data.to_hash)
  	redirect_to uploads_path
  end

  def challenge_participants
		data = HashableCSV.new params[:upload][:data].tempfile
  	PredictionData.import_challenge_participants(data.to_hash)
  	redirect_to uploads_path, notice: 'Upload completed'
  end

  def generate_prediction_data
    # drop it like it's hot
    PredictionData.delete_all
    PredictionData.generate
  	send_data PredictionData.to_csv, filename: 'prediction_data.csv'
  end

  def upload_prediction_data
    PredictionData.delete_all
    PredictionData.generate

    gs = GoogleStorage.new
    gs.upload_prediction_data(PredictionData.to_csv)

    redirect_to root_path, notice: 'Successfully uploaded Prediction Data'
  end

end
