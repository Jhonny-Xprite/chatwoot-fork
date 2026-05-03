begin
  di = DataImport.last
  if di
    puts "ID: #{di.id}"
    puts "Status: #{di.status}"
    puts "Total: #{di.total_records}"
    puts "Processed: #{di.processed_records}"
    if di.failed_records.attached?
      puts 'Failed records file attached: Yes'
    else
      puts 'Failed records file attached: No'
    end
  else
    puts 'No DataImport found'
  end

  puts "Total Contacts: #{Contact.count}"
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
