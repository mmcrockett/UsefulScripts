require 'nokogiri'
require 'open-uri'

class EspnBowlParser
  attr_reader :data

  FILE = File.join('', 'Users', 'mcrockett', 'UsefulScripts.mmcrockett', 'EspnPickEm.html')
  KEYS = [:away, :home, :away_percent, :home_percent, :away_confidence, :home_confidence]

  def initialize()
    @data = []

    puts "Loading: '#{FILE}'"
    page = Nokogiri::HTML(File.read(FILE))
    page.css('.matchupRow').each do |matchup_html|
      matchup  = {}
      percents = []

      matchup_html.css('td.picked').each do |td|
        td.css('span.wpw-percent-value').each do |percent_span|
          percents << percent_span.text().strip()
        end
      end

      matchup_html.css('div.pickem-teams').each do |div|
        team  = div.css('span.pickem-team-name')[0].css('span.link-text')[0].text().strip()
        parts = team.split(' ')

        team  = parts[0]

        if (2 < parts.size)
          team << " #{parts[1]}"
        end

        if (false == matchup.include?(:away))
          matchup[:away] = team
          matchup[:away_percent] = percents.first.chop
        else
          matchup[:home] = team
          matchup[:home_percent] = percents.last.chop
        end
      end

      @data << matchup
    end
  end

  def to_s
    str  = ""

    KEYS.each do |key|
      str += "#{key}\t"
    end

    str.chomp("\t")
    str += "\n"

    @data.each do |matchup|
      KEYS.each do |key|
        str += "#{matchup[key]}\t"
      end

      str.chomp("\t")
      str += "\n"
    end

    return str
  end

  def columnized
    KEYS.each do |k|
      puts "===#{k}==="
      @data.each do |v|
        puts "#{v[k]}"
      end
    end
  end
end

puts "#{EspnBowlParser.new.columnized}"
