require 'rubygems'
require 'icalendar'
require 'date'

class DateTime
  CDT_TIMEZONE = Rational(Integer(-5*60), (24*60))

  def self.create(date, hour, min)
    return DateTime.civil(date.year, date.month, date.mday, hour, min, CDT_TIMEZONE)
  end
end

class OutputCalendar
  #DATE_FORMAT = "%m/%d/%y"
  DATE_FORMAT = "%m/%d/%Y"
  FILENAME_BASE = "EventSchedule"

  def initialize()
    @ical   = Icalendar::Calendar.new
  end

  def create(events, summary, length)
    filename = "#{FILENAME_BASE}-#{summary.gsub(" ", "")}.ics"
    dates = []

    events.each do |e|
      parts = e.split(' ')
      date = Date.strptime(parts[0], DATE_FORMAT)
      hour  = 0
      min   = 0

      if (e.upcase.index("PM"))
        hour = 12
      end

      if (nil != parts[1])
        hour = hour + Integer(parts[1].split(":")[0])
        min  = Integer(parts[1].split(":")[1])
      end

      event = @ical.event

      event.start = DateTime.create(date, hour, min)
      event.end   = DateTime.create(date, hour + length, min)
      event.summary = summary
    end

    f = File.open(filename, 'w')
    f.puts(@ical.to_ical())
    f.close()
    puts "Done writing file '#{filename}'."
  end
end

events = []
events << "9/27/2014 11:00 AM"
events << "10/4/2014 10:00 AM"
events << "10/11/2014 9:00 AM"
events << "10/18/2014 11:00 AM"
events << "10/25/2014 10:00 AM"
events << "11/1/2014 9:00 AM"
events << "11/8/2014 9:00 AM"
events << "11/15/2014 9:00 AM"
#events << "3/1/14 11:00 AM"

OutputCalendar.new().create(events, "Charlotte Soccer", 1)
