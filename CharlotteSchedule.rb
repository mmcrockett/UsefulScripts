require 'rubygems'
require 'icalendar'
require 'date'

class Date
  DATE_FORMAT = "%Y%m%d"
  CHANGE_DATE = Date.strptime("20131020", Date::DATE_FORMAT)
  ODD_WEEKS   = [1,3,5]

  def yeven?()
    if (0 == (self.year % 2))
      return true
    else
      return false
    end
  end

  def friday?()
    if (DAYNAMES.index("Friday") == self.wday)
      return true
    else
      return false
    end
  end

  def extended?()
    if (CHANGE_DATE <= self)
      return true
    end

    return false
  end

  def wodd?()
    if (true == ODD_WEEKS.include?(self.nth()))
      return true
    end

    return false
  end

  def to_s()
    return self.strftime(DATE_FORMAT)
  end

  def prev_wednesday()
    return self.previous("Wednesday")
  end

  def prev_thursday()
    return self.previous("Thursday")
  end

  def next_monday()
    return self.next("Monday")
  end

  def next_saturday()
    return self.next("Saturday")
  end

  def next_sunday()
    return self.next("Sunday")
  end

  def next(wday)
    if (String == wday.class())
      wday = DAYNAMES.index(wday)
    end

    new_date = self + 1

    while (wday != new_date.wday)
      new_date = new_date + 1
    end

    return new_date
  end

  def previous(wday)
    if (String == wday.class())
      wday = DAYNAMES.index(wday)
    end

    new_date = self - 1

    while (wday != new_date.wday)
      new_date = new_date - 1
    end

    return new_date
  end

  def nth()
    return (self.mday + 6)/7
  end

  def labor_day?()
    if ((MONTHNAMES.index("September") == self.month()) and (1 == self.nth()) and (DAYNAMES.index("Monday") == self.wday()))
      return true
    end

    return false
  end

  def memorial_day?()
    if ((MONTHNAMES.index("May") == self.month()) and (31 < (self.day + 7)) and (DAYNAMES.index("Monday") == self.wday()))
      return true
    end

    return false
  end

  def after_christmas_time?()
    if (
        ((MONTHNAMES.index("December") == self.month()) and (28 <= self.day())) or
        ((MONTHNAMES.index("January") == self.month()) and (2 >= self.day()))
       )
      return true
    end

    return false
  end

  def christmas_time?()
    if ((MONTHNAMES.index("December") == self.month()) and (20 <= self.day()) and (26 >= self.day()))
      return true
    end

    return false
  end

  def fathers_day?()
    if ((MONTHNAMES.index("June") == self.month()) and (3 == self.nth()) and (DAYNAMES.index("Sunday") == self.wday()))
      return true
    end

    return false
  end

  def mothers_day?()
    if ((MONTHNAMES.index("May") == self.month()) and (2 == self.nth()) and (DAYNAMES.index("Sunday") == self.wday()))
      return true
    end

    return false
  end

  def thanksgiving?()
    if ((MONTHNAMES.index("November") == self.month()) and (4 == self.nth()) and (DAYNAMES.index("Thursday") == self.wday()))
      return true
    end

    return false
  end

  def charlottes_birthday?()
    if ((MONTHNAMES.index("October") == self.month()) and (20 == self.day()))
      return true
    end

    return false
  end

  def designation_reminder?()
    if ((MONTHNAMES.index("March") == self.month()) and (1 == self.day()))
      return true
    end

    return false
  end
end

class DateTime
  CDT_TIMEZONE = Rational(Integer(-5*60), (24*60))

  def self.create(date, hour)
    return DateTime.civil(date.year, date.month, date.mday, hour, 0, CDT_TIMEZONE)
  end
end

class OutputCalendar
  START_DATE  = Date.strptime("20150101", Date::DATE_FORMAT)
  END_DATE    = Date.strptime("20160101", Date::DATE_FORMAT)
  FILENAME    = "CharlotteSchedule-#{START_DATE}-#{END_DATE}.ics"

  def initialize()
    @ical   = Icalendar::Calendar.new
  end

  def add_weekend(friday)
    saturday = friday.next_saturday()
    sunday   = friday.next_sunday()

    sched["#{friday}"]   = DateTime.create(friday, 17)
    sched["#{saturday}"] = DateTime.create(saturday, 18)
    sched["#{sunday}"]   = DateTime.create(sunday, 18)
  end

  def remove_weekend(friday)
    saturday = friday.next_saturday()
    sunday   = friday.next_sunday()

    sched.delete("#{friday}")
    sched.delete("#{saturday}")

    if (false == sched.include?("#{friday.next_monday()}"))
      sched.delete(sunday)
    end
  end

  def extend_weekend(friday)
    add_thursday(friday.prev_thursday())
    add_monday(friday.next_monday())
  end

  def add_monday(monday)
    sched["#{monday()}"] = DateTime.create(monday, 18)
  end

  def add(day)
    sched["#{day}"] = DateTime.create(day, 17)
  end

  def remove(day)
    sched.delete("#{day}")
  end

  def thanksgiving(friday)

    if (true == friday.yeven?())
      if ((true == friday.extended?()) and (true == friday.wodd?()))
        event = @ical.event
        event.start = DateTime.create(friday.next_sunday(), 18)
        event.end   = DateTime.create(friday.next_monday(), 18)
        event.summary = "Charlotte Thanksgiving"
      end
    else
      event = @ical.event
      event.start = DateTime.create(friday.previous("Tuesday"), 17)

      if ((true == friday.extended?()) and (true == friday.wodd?()))
        event.end = DateTime.create(friday.next_monday(), 18)
      else
        event.end = DateTime.create(friday.next_sunday(), 18)
      end

      event.summary = "Charlotte Thanksgiving"
    end
  end

  def fathers_day(friday)
    event = @ical.event

    event.start = DateTime.create(friday, 17)
    event.end   = DateTime.create(friday.next_sunday(), 18)
    event.summary = "Charlotte Fathers Day"
  end

  def even_week(friday)

    if (true == friday.extended?())
      wed = @ical.event
      wed.start = DateTime.create(friday.prev_wednesday(), 17)
      wed.end   = DateTime.create(friday.prev_thursday(), 9)
      wed.summary = "Charlotte Overnight"
    end

    event = @ical.event
    event.start = DateTime.create(friday.prev_thursday(), 17)
    event.end   = DateTime.create(friday, 9)
    event.summary = "Charlotte Overnight"
  end

  def mothers_day(friday)
    thursday = friday.prev_thursday()

    if (true == friday.extended?())
      thurs = @ical.event
      thurs.start = DateTime.create(thursday, 17)
      thurs.end   = DateTime.create(friday, 18)
      thurs.summary = "Charlotte Overnight"

      sun = @ical.event
      sun.start = DateTime.create(friday.next_sunday(), 18)
      sun.end   = DateTime.create(friday.next_monday(), 18)
      sun.summary = "Charlotte Overnight"
    else
      dinner = @ical.event
      dinner.start = DateTime.create(thursday, 17)
      dinner.end   = DateTime.create(thursday, 19)
      dinner.summary = "Charlotte Dinner"
    end
  end

  def odd_week(friday)
    event    = @ical.event
    thursday = friday.prev_thursday()
    monday   = friday.next_monday()

    if (true == friday.extended?())
      event.start = DateTime.create(thursday, 17)
      event.end   = DateTime.create(monday, 18)
    else
      dinner = @ical.event
      dinner.start = DateTime.create(thursday, 17)
      dinner.end   = DateTime.create(thursday, 19)
      dinner.summary = "Charlotte Dinner"

      event.start = DateTime.create(friday, 17)

      if ((true == monday.memorial_day?()) or (true == monday.labor_day?()))
        event.end   = DateTime.create(monday, 18)
      else
        event.end   = DateTime.create(friday.next_sunday(), 18)
      end
    end

    event.summary = "Charlotte Weekend"
  end

  def create()
    puts "Start: #{START_DATE} : #{END_DATE}"

    START_DATE.upto(END_DATE) do |day|
      if (true == day.friday?())
        if (true == day.prev_thursday().thanksgiving?())
          thanksgiving(day)
        elsif (true == day.wodd?())
          if (true == day.next_sunday().mothers_day?())
            mothers_day(day)
          else
            odd_week(day)
          end
        else
          even_week(day)

          if (true == day.next_sunday().fathers_day?())
            fathers_day(day)
          end
        end
      end
    end

    f = File.open(FILENAME, 'w')
    f.puts(@ical.to_ical())
    f.close()
  end
end

OutputCalendar.new().create()
