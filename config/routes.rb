ParasquidCs2001::Application.routes.draw do
  root to: "welcome#index"

  get "querying" => 'querying#index'

  get "uploads" => 'uploads#index'
  post "upload_prediction_data" => "uploads#upload_prediction_data"
  
  namespace :uploads do
    post "challenge_platforms"
    post "challenge_technologies"
    post "challlenges"
    post "challenge_participants"
    get "generate_prediction_data"
  end

  match '/query' => Prediction, anchor: false
end
