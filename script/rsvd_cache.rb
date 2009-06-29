include Algorithms::Rank::RSVD
for question in Question.all(:select => 'id')
  begin
    puts "-- start question id: #{question.id}"
    svd(question.id)
    puts "-- end question id: #{question.id}"
  rescue Linalg::Exception::DimensionError
    puts "-- not enough data for question id: #{question.id}"
  end
end