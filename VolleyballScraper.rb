require 'rubygems'
require 'open-uri'
require 'icalendar'
require 'date'

class DateTime
  CDT_TIMEZONE = Rational(Integer(-5*60), (24*60))

  def self.create(date, hour, min)
    return DateTime.civil(date.year, date.month, date.mday, hour, min, CDT_TIMEZONE)
  end
end

class OutputCalendar
  DATE_FORMAT = "%B %e, %Y"
  FILENAME    = "VolleyballSchedule.ics"
  DELIMITER   = "@"

  def initialize()
    @ical   = Icalendar::Calendar.new
    @url    = "http://austinssc.com/tracker_volleyball_2/index.php?opt=viewteam&id=0428&sid=000000000009"
    @events = []
  end

  def removetd(s)
    s.strip!
    gt = s.index('>')
    lt = nil
    
    if (nil != gt)
      lt = s.index('<', gt)
    end

    if (nil != gt)
      if (nil != lt)
        return "#{s[gt+1..lt-1]}"
      else
        return "#{s[gt+1..-1]}"
      end
    else
      return s
    end
  end

  def parse()
    schedule_found = false
    schedule_keyword = "2014 Schedule"
    date = nil
    time = nil
    i    = 0

    open(@url).each_line do |line|
      if (true == schedule_found)
        line = removetd(line)
        i += 1

        if (nil == date)
          begin
            Date.strptime(line, DATE_FORMAT)
            date = line
            i = 0
          rescue
          end
        elsif (nil == time)
          time = "#{DELIMITER}#{line.delete("pm")}"
        elsif (5 == i)
          value = "#{date}#{time}"

          begin
            Integer(line)
            puts "Ignoring: #{value}"
          rescue
            puts "Adding: #{value}"
            @events << "#{value}"
          end

          date = nil
          time = nil
        end
      elsif (true == line.include?("#{schedule_keyword}"))
        schedule_found = true
      end
    end

    if (false == schedule_found)
      raise "!ERROR: Unable to find #{schedule_keyword}."
    end

    return self
  end

  def create(summary, length)
    @events.each do |e|
      event = @ical.event
      parts = e.split("#{DELIMITER}")
      hour  = 0
      min   = 0

      date = Date.strptime(parts[0], DATE_FORMAT)

      if (nil != parts[1])
        hour = 12 + Integer(parts[1].split(":")[0])
        min  = Integer(parts[1].split(":")[1])
      end

      event.start = DateTime.create(date, hour, min)
      event.end   = DateTime.create(date, hour + length, min)
      event.summary = summary
    end

    f = File.open(FILENAME, 'w')
    f.puts(@ical.to_ical())
    f.close()
  end
end

OutputCalendar.new().parse().create("Sand Volleyball", 1)
