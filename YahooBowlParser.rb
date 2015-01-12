require 'nokogiri'
require 'open-uri'

class YahooBowlParser
  URLS = [
    "http://football.fantasysports.yahoo.com/bowl/schedule",
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
            team   = tr.css('span.team-name')[0].css('a')[0].text().strip()
            spread = tr.css('td.spread')[0].text().strip().to_f

            if (0 != spread)
              percent = tr.css('td.pick-percent')[0].text().strip()
              matchup[:favorite] = team
              matchup[:percent]  = percent.chop
              matchup[:spread]   = spread
            else
              matchup[:underdog] = team
            end
          rescue
          end
        end
        @data << matchup
      end
    end
  end

  def to_s
    str = ""

    @data.each do |matchup|
      str += "#{matchup[:favorite]}\t#{matchup[:underdog]}\t#{matchup[:percent]}\t#{matchup[:spread]}\n"
    end

    return str
  end
end

puts "#{YahooBowlParser.new}"
