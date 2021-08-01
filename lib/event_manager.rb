require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone(phone_number)
  clean_number = phone_number.gsub!(/[^0-9]/, '')
  return "BAD_NUMBER" if clean_number.nil?
  num_len = clean_number.size

  if num_len == 10
    clean_number
  elsif num_len == 11 && clean_number[0] == "1"
    clean_number[1..10]
  else
    "BAD_NUMBER"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_hash = Hash.new(0)
date_hash = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = row[:zipcode]
  phone = clean_phone(row[:homephone])

  reg_date = row[:regdate]
  date_arr = reg_date.tr("/ :", " ").split(" ")
  date = DateTime.strptime(reg_date, '%m/%d/%y %H:%M')

  hour_hash[date.hour] += 1
  date_hash[date.wday] += 1

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

peak_hour = hour_hash.max_by { |k, v| v }
peak_date = date_hash.max_by { |k, v| v }

dates = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

puts "Peak hour: #{peak_hour}"
puts "Peak date: #{peak_date}"
