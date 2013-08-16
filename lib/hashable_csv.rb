require 'csv'

class HashableCSV < CSV
  def to_hash
    headers = self.shift.map {|i| i.to_s }
    string_data = self.map {|row| row.map {|cell| cell.to_s } }
    array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten] }
  end
end