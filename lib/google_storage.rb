class GoogleStorage

  def download_csv_data
    conn = Faraday::Connection.new()
    %w(challenges challenge-participants challenge-platforms challenge-technologies).inject({}) do |ret, key|
      result = api_client.execute(
        api_method: storage.objects.get,
        connection: conn,
        parameters: {bucket: ENV["GOOGLE_STORAGE_BUCKET_NAME"], object: "#{key}-export.csv", alt: "media"}        
      )
      if result.status == 404
        p "File #{key} does not exist on Google Cloud Storage."
      elsif result.status == 307

        headers = result.request.to_env(conn)[:request_headers]
        resp = HTTParty.get(result.response.headers['location'], headers: headers)
        ret[key] = resp.body
      else 

        ret[key] = result.body
      end

      ret
    end
  end

  def upload_prediction_data(data)
    api_client.execute(
      api_method: storage.objects.insert,
      headers: { content_type: "text/csv" },
      parameters: {
          uploadType: 'media', 
          bucket: ENV["GOOGLE_STORAGE_BUCKET_NAME"], 
          name: ENV["PREDICTION_DATA_OBJECT"]
      },
      body: data
    )    
  end

  private
  def storage
    @storage ||= api_client.discovered_api('storage', 'v1beta2')
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