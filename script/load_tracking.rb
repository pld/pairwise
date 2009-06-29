FILE_LOC = 'vote_dump.csv'

data = IO.readlines(FILE_LOC)
data.shift
data.each do |el|
  row = el.split("\t")
  vote = Vote.find(row.shift)
  country_code = row.shift
  tracking = row.shift.chomp
  tracking += ":#{country_code}" unless country_code == 'NULL'
#  puts "#{vote.id} - #{tracking}"
  vote.update_attribute(:tracking, tracking)
end