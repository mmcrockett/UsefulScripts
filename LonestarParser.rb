require 'nokogiri'
require 'date'
gem 'icalendar', '1.5.4'
require 'icalendar'
require 'byebug'

class DateTime
  CDT_TIMEZONE = Rational(Integer(-5*60), (24*60))

  def self.create(date, hour, minute)
    return DateTime.civil(date.year, date.month, date.mday, hour, minute, CDT_TIMEZONE)
  end
end

class LonestarGame
  attr_accessor :description, :location, :date, :time

  def initialize()
  end

  def to_s
    return "#{@date} - #{@time} - #{@description} - #{@location}"
  end
end

class LonestarParser
  FILENAME    = "CharlotteSoccerSchedule.ics"

  # Download from Google Docs as zipped html.
  # Unzip and then run on html files.
  def initialize(params = {})
    directory = params[:directory]
    @files    = []

    if (false == Dir.exist?(directory))
      raise "Need valid directory parameter not '#{directory}'."
    else
      glob   = File.join(directory, "*.html")
      @files = Dir.glob(glob)

      if (true == @files.empty?)
        raise "Couldn't find any files '#{glob}'."
      end
    end
  end

  def process
    @games = []

    @files.each do |f|
      game_dates = []

      page = Nokogiri::HTML(File.open(f).read())
      page.css('tbody')[0].css('tr').each do |tr|
        if (true == game_dates.empty?)
          if ((true == tr.text.downcase.include?("saturday")) || (true == tr.text.downcase.include?("sunday")))
            game_dates = process_date_cell(tr)
          end
        else
          if (true == LonestarParser.italy_girls?(tr))
            @games << process_game(tr, game_dates)
          end
        end
      end
    end

    return self
  end

  def to_s
    return @games * ' '
  end

  def to_ical(filename = nil)
    ical = Icalendar::Calendar.new

    @games.each do |game|
      event = ical.event
      event.summary = game.description
      event.start   = DateTime.create(game.date, game.time.hour, game.time.minute)
      event.end     = DateTime.create(game.date, game.time.hour + 2, game.time.minute)
      event.location = game.location
      #event.uid     = "z"
    end

    if (nil != filename)
      f = File.open(filename, 'w')
      f.puts(ical.to_ical())
      f.close()
    end

    return ical
  end

  private
  def process_date_cell(tr)
    game_dates = []

    tr.css('td').each_with_index do |td, i|
      if (false == td.text.strip.empty?)
        begin
          d = DateTime.parse(td.text)

          game_dates << d
        rescue
        end
      end
    end

    return game_dates
  end

  def process_game(tr, game_dates)
    game   = LonestarGame.new
    time_index        = -1
    tds               = tr.css('td')

    tds.each_with_index do |td, i|
      if (false == td.text.strip.empty?)
        if (0 == time_index)
          time_index = i
        end
      else
        time_index = 0
      end

      if (true == LonestarParser.italy_girls?(td))
        break
      end
    end

    game.time = DateTime.parse(tds[time_index].text.strip)

    if (1 == time_index)
      game.date = game_dates.first
    else
      game.date = game_dates.last
    end
    game.description = "#{tds[time_index + 1].text.strip} vs #{tds[time_index + 2].text.strip}"
    game.location    = tds[time_index + 3].text.strip

    return game
  end

  def self.italy_girls?(html_node)
    return ((true == html_node.text.downcase.include?("italy")) && (true == html_node.text.downcase.include?("girls")))
  end
end

file = File.join('', 'Users', 'mcrockett', 'Desktop', LonestarParser::FILENAME)
LonestarParser.new({:directory => File.join('', 'Users', 'mcrockett', 'Desktop', 'LonestarSoccerSchedule')}).process.to_ical(file)
