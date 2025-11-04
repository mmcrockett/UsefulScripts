require 'httparty'
require 'json'
require 'time'
require 'tzinfo'

class BallButton
  include HTTParty

  COURT_5 = 1176
  API_URL = '/api/v1/appointment/add_book'
  BASE_URL = 'https://balbuton.com'
  CHICAGO_TZ = TZInfo::Timezone.get('America/Chicago')

  TOKEN = # copy me from browser some long jwt token 'eyJhbGc....'
  USER_ID = # copy me from browser
  USER_NAME = 'bob'

  headers(
    'Content-Type' => 'application/json',
    'x-location-id': '134',
    'x-facility-group-id': '144',
    'x-access-token': TOKEN
  )
  base_uri(BASE_URL)

  def self.reserve(dry_run: false)
    next_week = Time.now + (7 * 24 * 60 * 60)
    start_time = CHICAGO_TZ.local_time(next_week.year, next_week.month, next_week.day, 7, 30, 0)
    end_time = CHICAGO_TZ.local_time(next_week.year, next_week.month, next_week.day, 9, 0, 0)

    data = {
      start_time: start_time.utc.iso8601,
      end_time: end_time.utc.iso8601,
      instantBook: true,
      courts: [COURT_5],
      userId: USER_ID,
      force: false,
      sport_id: "1",
      fullName: USER_NAME,
      assigned: [],
      tags: [],
      partners: [],
      guests: [],
      add_on_id: nil
    }

    puts data.to_json
    dry_run ? self.get('') : self.post(API_URL, body: data.to_json)
  end
end

puts BallButton.reserve(dry_run: 'true' == ENV['DRY_RUN']).parsed_response
