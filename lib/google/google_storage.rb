class GoogleStorage

  def upload_prediction_data(data)
    storage = api_client.discovered_api('storage', 'v1beta2')
    api_client.execute(
      api_method: storage.objects.insert,
      parameters: {
          uploadType: 'media', 
          bucket: ENV["GOOGLE_STORAGE_BUCKET_NAME"], 
          name: ENV["PREDICTION_DATA_OBJECT"]
      },
      body: data
    )    
  end

  def api_client
    @api_client ||= begin
      client = Google::APIClient.new(application_name: ENV["APP_NAME"])

      # Authorize service account
      keyfile = Rails.root.join 'config', ENV["GOOGLE_KEYFILE"]
      key = Google::APIClient::PKCS12.load_key(keyfile, ENV["GOOGLE_PASSPHRASE"])
      asserter = Google::APIClient::JWTAsserter.new(
         ENV["GOOGLE_CLIENT_EMAIL"],
         'https://www.googleapis.com/auth/devstorage.full_control',
         key)
      client.authorization = asserter.authorize()    
      client
    end
  end

end