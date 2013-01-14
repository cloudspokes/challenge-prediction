ParasquidCs2001::Application.routes.draw do
  get "querying" => 'querying#index'

  get "uploads" => 'uploads#index'
  namespace :uploads do
    post "challenge_categories"
    post "challlenges"
    post "challenge_participants"
    get "generate_prediction_data"
  end

end
