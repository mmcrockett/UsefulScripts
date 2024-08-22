require 'rubygems'
require 'icalendar'
require 'date'
require 'csv'

tsv_data =<<-TSV
Day	Date	Team	Location	9th	JV	Varsity
Sat		Oct 26		Lake Travis (Scrimmage)	Away	TBA	TBA	TBA	
Tue		Oct 29		Hyde Park			Home	5:15	5:15	7:00
Fri		Nov 1		Dripping Springs		Home	5:15	5:30	7:00   	
Tue		Nov 5		Westlake			Away	5:15	5:30	7:30  	 
Fri		Nov 07-09 	 Converse Judson Tourney (Var)	Away
Tue		Nov 12		Copperas Cove		Away	5:30	5:30      7:00
Thu & Sat	Nov 14-16	I-45 ShowdownTourney (All)	Away			TBA
Tue		Nov 19		*Vista Ridge			Away	5:15	5:30     7:00     
Fri		Nov 22		San Marcos			 Home	5:15	5:30	7:00	
Tue		Nov 26		*McNeil			Away	11:00	11:30	1:00			  
Tue		Dec 3		*Cedar Ridge			Home 	5:15	5:30	7:00 
Fri		Dec 6		*Vandegrift			Home	5:15	5:30	7:00 
Fri		Dec 10		*Manor				Away	5:15	5:30	7:00
Fri		Dec 13		*Hutto				Home	5:15	5:30	7:00 (Future Warrior)
Sat		Dec 14		Sub Varsity Wimberley Tourney  Away	TBA	TBA
Fri & Sat	Dec 27-28	Austin High Tourney (Var)	Away			TBA		
Tue		Dec 31		*Round Rock			Away 	11:00	11:30	1:00
Fri		Jan 3		*Stony Point			Home	11:00	11:30	1:00 
Tue		Jan 7		*Vandegrift			Away	5:15	5:30	7:00
Fri		Jan 10		*Vista Ridge			Home	5:15	5:30	7:00 
Tue		Jan 14		*McNeil			Home	5:15	5:30	7:00 (Teacher Appreciation)
Fri		Jan 17		*Cedar Ridge		Away	5:15	5:30	7:00
Tue		Jan 21		*Manor			Home 	5:15	5:30	7:00 
Fri		Jan 24		*Hutto				Away 	5:15	5:30	7:00 
Fri		Jan 31		*Round Rock			Home	5:15	5:30	7:00 (Senior Night)
Tue		Feb 4		*Stony Point			Away	5:15	5:30	7:00
TSV

csv_data = tsv_data.gsub(/[\t]+/, ',')
events = CSV.parse(csv_data, headers: true, header_converters: :symbol).map do |row|
  (start_d, end_d) = row[:date].strip.split('-')
  time = row[:varsity]
  note = "#{row[:location].strip != 'Home' ? '@' : ''}#{row[:team].strip}"

  if (time.nil? || 'TBA' == time)
    time = '5:00 pm'
    note = "(check time) #{note}"
  else
    time = "#{time.split.first} pm"
  end

  end_d   = Date.parse("#{start_d.split.first} #{end_d}") if end_d
  start_d = Date.parse(start_d)


  [start_d, end_d].compact.map {|t| ["#{t} #{time}", note] }
end.flatten(1)

class DateTime
  CDT_TIMEZONE = Rational(Integer(-5*60), (24*60))

  def self.create(date, hour, min)
    return DateTime.civil(date.year, date.month, date.mday, hour, min, CDT_TIMEZONE)
  end
end

class OutputCalendar
  FILENAME_BASE = "EventSchedule"

  def initialize()
    @ical   = Icalendar::Calendar.new
  end

  def create(events, summary, length = 1)
    filename = "#{FILENAME_BASE}-#{summary.gsub(" ", "")}.ics"
    dates = []

    events.each do |datestr, title|
      parts = datestr.split(' ')
      date = Date.parse(parts[0])
      hour  = 0
      min   = 0

      if (datestr.upcase.include?('PM'))
        hour = 12
      end

      if (nil != parts[1])
        hour = hour + Integer(parts[1].split(":")[0])
        min  = Integer(parts[1].split(":")[1])
      end

      event = @ical.event

      event.start = DateTime.create(date, hour, min)
      event.end   = DateTime.create(date, hour + length, min)
      event.summary = title || summary
    end

    f = File.open(filename, 'w')
    f.puts(@ical.to_ical())
    f.close()
    puts "Done writing file '#{filename}'."
  end
end

OutputCalendar.new().create(events, "westwood-bball")
