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
  TEAMNAME    = "Poland"

  # Download html.
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
      page = Nokogiri::HTML(File.open(f).read())
      page.css('tbody').each do |tbody|
        current_date = nil

        tbody.css('tr').each do |tr|
          if ((true == tr.text.downcase.include?("saturday")) || (true == tr.text.downcase.include?("sunday")))
            current_date = process_date_cell(tr)
          end

          if (false == current_date.nil?)
            if (true == LonestarParser.charlotte_team?(tr))
              @games << process_game(tr, current_date)
            end
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
      puts "Game on #{game.date.to_date} @ #{game.time.hour}:#{game.time.minute}."
      event = ical.event
      event.summary = game.description
      event.start   = DateTime.create(game.date, game.time.hour, game.time.minute)
      event.end     = DateTime.create(game.date, game.time.hour + 2, game.time.minute)
      event.location = game.location
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
    game_date = nil

    tr.css('td').each_with_index do |td, i|
      if (false == td.text.strip.empty?)
        begin
          d = DateTime.parse(td.text)

          if (true == game_date.nil?)
            game_date = d
          else
            raise "Not expected format, two game dates found '#{d}' and '#{game_date}."
          end
        rescue
        end
      end
    end

    return game_date
  end

  def process_game(tr, game_date)
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

      if (true == LonestarParser.charlotte_team?(td))
        break
      end
    end

    game.time = DateTime.parse(tds[time_index].text.strip)

    game.date        = game_date
    game.description = "#{tds[time_index + 1].text.strip} vs #{tds[time_index + 2].text.strip}"
    game.location    = tds[time_index + 3].text.strip

    return game
  end

  def self.charlotte_team?(html_node)
    return ((true == html_node.text.downcase.include?(TEAMNAME.downcase)) && (true == html_node.text.downcase.include?("girls")))
  end
end

file = File.join('', 'Users', 'mcrockett', 'Desktop', LonestarParser::FILENAME)
LonestarParser.new(:directory => File.join('', 'Users', 'mcrockett', 'Desktop', 'LonestarSoccerSchedule')).process.to_ical(file)
puts "Created '#{file}'."
