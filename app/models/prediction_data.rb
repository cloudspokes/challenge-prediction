class PredictionData
	include Mongoid::Document

	field :categories, type: Array, default: []
	field :submitters, type: Array, default: []
	field :total_prize, type: Integer, default: 0
	field :top_prize, type: Integer, default: 0
	field :challenge_length, type: Integer, default: 0
	field :passing_submissions, type: Float, default: 0.0

	def self.import_challenge_categories(data)
		column_name = :challenge_categories
		DB.drop_table?(column_name)
		DB.create_table(column_name) do
			String "Category__r.Name"
			String "Challenge__r.Challenge_Id__c"
		end
		insert_into_database(data, column_name)
	end

	def self.import_challenges(data)
		column_name = :challenges
		DB.drop_table?(column_name)
		DB.create_table(column_name) do
			String "Challenge_Id__c"
			Integer "Length_of_Contest__c"
			String "Top_Prize__c" # this field has dollar signs :(
			Integer "Total_Prize_Money__c"
		end
		insert_into_database(data, column_name)
	end

	def self.import_challenge_participants(data)
		column_name = :challenge_participants
		DB.drop_table?(column_name)
		DB.create_table(column_name) do
			String "Member__r.Name"
			String "Challenge__r.Challenge_Id__c"
			Float "Score__c" # a score of more than 75.00 is a valid submission
		end
		insert_into_database(data, column_name)
	end

	def self.generate
		# generate the prediction data lines
		# categories.join(' '), submitters.join(' '), total_prize, top_prize, challenge_length, passing_submissions
		lines = {}

		# reduce the challenge categories into lines and arrays by creating a hash
		# {:challenge_id => [category1, category2, category3]}
		DB[:challenge_categories].each do |row|
			lines[row[:"Challenge__r.Challenge_Id__c"]] ||= {}
			lines[row[:"Challenge__r.Challenge_Id__c"]][:categories] ||= []
			lines[row[:"Challenge__r.Challenge_Id__c"]][:categories].push(row[:"Category__r.Name"])
		end

		# include the challenge info
		DB[:challenges].each do |row|
			lines[row[:"Challenge_Id__c"]] ||= {}
			lines[row[:"Challenge_Id__c"]][:challenge_length] = row[:"Length_of_Contest__c"]
			lines[row[:"Challenge_Id__c"]][:top_prize] = row[:"Top_Prize__c"].to_s.gsub('$','').gsub(',','').to_i
			lines[row[:"Challenge_Id__c"]][:total_prize] = row[:"Total_Prize_Money__c"]
			puts lines[row[:"Challenge_Id__c"]][:top_prize]
		end

		# include the submitters
		DB[:challenge_participants].each do |row|
			lines[row[:"Challenge__r.Challenge_Id__c"]] ||= {}
			lines[row[:"Challenge__r.Challenge_Id__c"]][:submitters] ||= []
			lines[row[:"Challenge__r.Challenge_Id__c"]][:submitters].push(row[:"Member__r.Name"]) if row[:"Score__c"] > 0
			passing_submissions = lines[row[:"Challenge__r.Challenge_Id__c"]][:passing_submissions] ||= 0
			lines[row[:"Challenge__r.Challenge_Id__c"]][:passing_submissions] = passing_submissions + 1 if row[:"Score__c"] > 75
		end

		# create the database
		lines.each do |line|
			PredictionData.create line.last
		end

		# clear in-memory database
	end

  def self.to_csv(options={})
    CSV.generate(options) do |csv|
      self.all.each do |elem|
				csv << [elem.passing_submissions,
					"#{elem.categories.sort.join(' ')}",
					"#{elem.submitters.sort.join(' ')}",
					elem.total_prize,
					elem.top_prize,
					elem.challenge_length
				]
      end
    end
  end

	private

	def self.sanitize(data, column_names)
    data.each do |row|
			row.delete_if {|key, value| !column_names.include? key.to_sym}
		end
	end

	def self.insert_into_database(data, column_name)
		data = sanitize(data, DB[column_name].columns)
		data.each do |row|
			begin
				DB[column_name.to_sym].insert row
			rescue Exception => e
				Rails.logger.error e.inspect # log exceptions but continue anyway
			end
		end
	end
end