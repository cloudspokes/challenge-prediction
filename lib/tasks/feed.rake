desc "clears leaderboard from redis"
task :feed_data => :environment do
  gs = GoogleStorage.new

  puts " => Downloding CSV data from Google Cloud Storage...."
  csv_data = gs.download_csv_data

  puts " => Building prediction_data.csv...."
  csv_data.each do |key, data| 
    PredictionData.send("import_#{key.underscore}", HashableCSV.new(data).to_hash)
  end

  PredictionData.delete_all
  PredictionData.generate

  puts " => Uploading prediction_data.csv to Google Cloud Storage...."
  gs.upload_prediction_data(PredictionData.to_csv)
end
