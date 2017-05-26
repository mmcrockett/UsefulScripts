require 'nokogiri'
require 'open-uri'

class YahooBowlParser
  URLS = [
    "https://football.fantasysports.yahoo.com/bowl/schedule",
  ]

  def initialize()
    @data = []

    URLS.each do |url|
      puts "Loading: '#{url}'"
      page = Nokogiri::HTML(open("#{url}"))
      page.css('.matchup').each do |matchup_html|
        matchup = {}
        matchup_html.css('tbody')[0].css('tr').each do |tr|
          begin
            team       = tr.css('span.team-name')[0].css('a')[0].text().strip()
            confidence = tr.css('td.confidence')[0].text().strip()
            percent    = tr.css('td.pick-percent')[0].text().strip()

            if (false == matchup.include?(:away))
              matchup[:away] = team
              matchup[:away_confidence] = confidence
              matchup[:away_percent] = percent.chop
            else
              matchup[:home] = team
              matchup[:home_confidence] = confidence
              matchup[:home_percent] = percent.chop
            end
          rescue
          end
        end
        @data << matchup
      end
    end
  end

  def to_s
    keys = [:away, :home, :away_percent, :home_percent, :away_confidence, :home_confidence]
    str  = ""

    keys.each do |key|
      str += "#{key}\t"
    end

    str.chomp("\t")
    str += "\n"

    @data.each do |matchup|
      keys.each do |key|
        str += "#{matchup[key]}\t"
      end

      str.chomp("\t")
      str += "\n"
    end

    return str
  end
end

puts "#{YahooBowlParser.new}"
