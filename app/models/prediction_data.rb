require "csv"

class PredictionData
	include Mongoid::Document

	field :platforms, type: Array, default: []
	field :technologies, type: Array, default: []
	field :submitters, type: Array, default: []
	field :total_prize, type: Integer, default: 0
	field :top_prize, type: Integer, default: 0
	field :challenge_length, type: Integer, default: 0
	field :passing_submissions, type: Float, default: 0.0

	def self.session
		@session ||= Mongoid::Sessions.default
	end

	def self.import_challenge_platforms(data)
		column_name = :challenge_platforms
		session[column_name].drop
		session[column_name].insert(data)
	end

	def self.import_challenge_technologies(data)
		column_name = :challenge_technologies
		session[column_name].drop
		session[column_name].insert(data)
	end

	def self.import_challenges(data)
		column_name = :challenges
		session[column_name].drop
		session[column_name].insert(data)
	end

	def self.import_challenge_participants(data)
		column_name = :challenge_participants
		session[column_name].drop
		session[column_name].insert(data)
	end

	def self.generate
		# generate the prediction data lines
		# platforms.join(' '), technologies.join(' '), submitters.join(' '), total_prize, top_prize, challenge_length, passing_submissions
		lines = {}

		# reduce the challenge platforms into lines and arrays by creating a hash
		session[:challenge_platforms].find.each do |row|
			cid = row["Challenge__r.Challenge_Id__c"]
			lines[cid] ||= {}
			lines[cid][:platforms] ||= []
			lines[cid][:platforms].push(row["Platform__r.Name"])
		end

		session[:challenge_technologies].find.each do |row|
			cid = row["Challenge__r.Challenge_Id__c"]
			lines[cid] ||= {}
			lines[cid][:technologies] ||= []
			lines[cid][:technologies].push(row["Technology__r.Name"])
		end

		# include the challenge info
		session[:challenges].find.each do |row|
			cid = row["Challenge_Id__c"]
			lines[cid] ||= {}
			lines[cid][:challenge_length] = row["Length_of_Contest__c"].to_i
			lines[cid][:top_prize] = row["Top_Prize__c"].to_s.gsub('$','').gsub(',','').to_i
			lines[cid][:total_prize] = row["Total_Prize_Money__c"].to_i
		end

		# include the submitters
		session[:challenge_participants].find.each do |row|
			cid = row["Challenge__r.Challenge_Id__c"]
			score = row["Score__c"].to_f
			lines[cid] ||= {}
			lines[cid][:submitters] ||= []
			lines[cid][:submitters].push(row["Member__r.Name"]) if score > 0
			lines[cid][:passing_submissions] ||= 0
			lines[cid][:passing_submissions] += 1 if score > 75
		end

		# create the database
		lines.each do |cid, data|
			PredictionData.create data
		end

		# clear in-memory database
	end

  def self.to_csv(options={})
    CSV.generate(options) do |csv|
      self.all.each do |elem|
				csv << [elem.passing_submissions,
					"#{elem.platforms.sort.join(' ')}",
					"#{elem.technologies.sort.join(' ')}",
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