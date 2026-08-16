require 'httparty'
require 'json'
require 'time'
require 'tzinfo'

class BallButton
  include HTTParty

  COURT_5 = 1176
  COURT_5C = 1178
  COURT_5D = 1179
  COURT_6A = 1180
  COURT_6B = 1181
  API_URL  = '/api/v1'
  BASE_URL = 'https://balbuton.com'
  BOOKING_URL = "#{API_URL}/appointment/get"
  CHECK_IN_URL = "#{API_URL}/members_checkin/addcheckin"
  LIST_URL = "#{API_URL}/members/booking"
  RESERVE_URL = "#{API_URL}/appointment/add_book"
  CANCEL_URL = "#{API_URL}/appointment/cancel"
  CHICAGO_TZ = TZInfo::Timezone.get('America/Chicago')
  CHECKIN_WINDOW_BEFORE_MIN = 60
  CHECKIN_WINDOW_AFTER_MIN = 150

  USERS = JSON.parse(
    File.read("#{__dir__}/ball_button.users.json")
  )

  SCHEDULE = JSON.parse(
    File.read("#{__dir__}/ball_button.schedule.json")
  )

  COURTS = {
    '5' => COURT_5,
    '5C' => COURT_5C,
    '5D' => COURT_5D,
    '6A' => COURT_6A,
    '6B' => COURT_6B
  }

  headers(
    'Content-Type' => 'application/json',
    'x-location-id': '134',
    'x-facility-group-id': '144'
  )
  base_uri(BASE_URL)

  def initialize(user = ENV['BB_USER'])
    @user = user || 'Michael Crockett'
  end

  def central_time_at(days_offset: 0, hr: 0, min: 0)
    offset_time = Time.now + (days_offset * 24 * 60 * 60)

    CHICAGO_TZ.local_time(offset_time.year, offset_time.month, offset_time.day, hr.to_i, min.to_i, 0)
  end

  def central_time_human(time_str, format: :day)
    t = time_str.is_a?(String) ? Time.iso8601(time_str) : time_str
    f = case(format.to_sym)
        when :long
          '%A %B %d %Y %l:%M%p'
        when :time
          '%l:%M%p'
        when :compact_date
          '%Y%m%d'
        else
          '%A - %b %d'
        end

    t.localtime(CHICAGO_TZ.utc_offset).strftime(f)
  end

  def check_in_next
    # https://balbuton.com/api/v1/members_checkin/addcheckin/1592456
    # {"date":"2026-02-22T09:26:30-06:00","users":["176064"]}

    now = Time.now

    eligible = bookings.select do |booking|
      next false unless booking.checkins.nil? || booking.checkins.empty?

      minutes_until_start = (Time.parse(booking.start_time) - now) / 60.0
      minutes_until_start <= CHECKIN_WINDOW_BEFORE_MIN && minutes_until_start >= -CHECKIN_WINDOW_AFTER_MIN
    end

    next_check_in = eligible.min_by {|booking| (Time.parse(booking.start_time) - now).abs }

    if next_check_in.nil?
      puts "checkin: no booking within the checkin window at #{now}"
      return
    end

    puts "checkin: checking in booking #{next_check_in.id} (#{next_check_in.start_time}) at #{now}"

    BallButton.post(
      "#{CHECK_IN_URL}/#{next_check_in.id}",
      body: {date: central_time_at, users: [user_id]}.to_json,
      headers: user_token_header
    )
  end

  def generate_schedule
    check_in_next

    html_rows = bookings.sort_by {|booking| Time.parse(booking.start_time) }.map do |booking|
      symbol = booking.checkins.nil? || booking.checkins.empty? ? '➖' : '✅'
      time_display = [
          central_time_human(booking.start_time, format: :time),
          central_time_human(booking.end_time, format: :time)
      ].join(' - ')

      cancel_cell = if Time.parse(booking.start_time) > Time.now
        <<~CANCEL_HTML
          <button type="button" class="btn btn-sm btn-outline-danger rounded-circle p-0 d-inline-flex align-items-center justify-content-center" style="width:1.75rem;height:1.75rem;line-height:1;" data-apt-id="#{booking.id}" onclick="openCancelModal(this)">&times;</button>
        CANCEL_HTML
      else
        ''
      end

      <<~HTML
         <tr>
            <td>#{central_time_human(booking.start_time)}</td>
            <td>#{time_display}</td>
            <td>#{booking.court}</td>
            <td>#{symbol}</td>
            <td>#{cancel_cell}</td>
        </tr>
      HTML
    end

    html = <<~HTML
      <html>
      <head>
      <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
      <link rel="icon" type="image/x-icon" href="/images/paddle.ico">
      <link rel="icon" type="image/svg+xml" href="/images/paddle.svg">
      <link rel="apple-touch-icon" href="/images/paddle-180.png">
      <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous"></script>
        <meta charset="UTF-8">
        <title>🏓 JCC Pickleball</title>
      </head>
      <body class="p-3">
      <table class="table table-striped">
      <thead>
        <tr>
          <th scope="col">Date</th>
          <th scope="col">Time</th>
          <th scope="col">Court</th>
          <th scope="col">Checked In?</th>
          <th scope="col">Cancel</th>
        </tr>
        </thead>
        <tbody>
        #{html_rows.join("\n")}
        </tbody>
      </table>
      <figcaption class="blockquote-footer pt-3">
        #{central_time_human(Time.now, format: :long)}
      </figcaption>

      <div class="modal fade" id="cancelModal" tabindex="-1">
        <div class="modal-dialog">
          <div class="modal-content">
            <form method="post" action="cancel.php">
              <div class="modal-header">
                <h5 class="modal-title">Cancel booking</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
              </div>
              <div class="modal-body">
                <input type="hidden" name="apt_id" id="cancelAptId">
                <input type="text" name="confirm_date" class="form-control" placeholder="secret 8 digits" required>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                <button type="submit" class="btn btn-danger">Cancel booking</button>
              </div>
            </form>
          </div>
        </div>
      </div>
      <script>
        function openCancelModal(btn) {
          document.getElementById('cancelAptId').value = btn.getAttribute('data-apt-id');
          new bootstrap.Modal(document.getElementById('cancelModal')).show();
        }
      </script>
      </body>
      </html>
    HTML

    File.open('/home/washingrving/mmcrockett.com/jpickle.html', 'w') { |f| f.write(html) }
  end

  def user_id
    USERS[@user].first.to_s
  end

  def user_token
    USERS[@user].last
  end

  def user_token_header
    { 'x-access-token': user_token }
  end

  def bookings
    url = "#{LIST_URL}/#{user_id}"

    data = {
      startDate: central_time_at.to_datetime.iso8601,
      endDate: central_time_at(days_offset: 7, hr: 23).to_datetime.iso8601,
      type: '0',
      is_coach: false
    }

    @bookings ||= BallButton.post(
      url,
      body: data.to_json,
      headers: user_token_header
    ).parsed_response.dig('payload', 'bookings_history') || []

    @bookings.map do |appt|
      Struct.new(
        :id,
        :court,
        :checkins,
        :start_time,
        :end_time
      ).new(
        appt['id'],
        appt['court_names'],
        booking(appt['id']).checkins,
        appt['start_time'],
        appt['end_time']
      )
    end
  end

  def booking(booking_id)
    url = "#{BOOKING_URL}/#{booking_id}"

    booking = BallButton.get(url, headers: user_token_header).parsed_response['payload']

    Struct.new(
      :checkins,
      :start_time
    ).new(
      booking['checkins'],
      booking['start_time']
    )
  end

  def cancel(apt_id, confirm_date: nil)
    if confirm_date
      actual_date = central_time_human(booking(apt_id).start_time, format: :compact_date)
      return 'not allowed' unless confirm_date == actual_date
    end

    BallButton.post(
      "#{CANCEL_URL}/#{apt_id}",
      body: {cancel_for: 'court', apt_id: apt_id.to_s}.to_json,
      headers: user_token_header
    )
  end

  def reserve_today
    weekday = central_time_at.strftime('%A').downcase
    entries = SCHEDULE[weekday] || []

    entries.map do |entry|
      reserve(
        entry['start'],
        minutes: entry['duration'],
        court: entry['court'],
        dry_run: 'true' == ENV['DRY_RUN']
      )
    end
  end

  def reserve(start, minutes: nil, court: nil, dry_run: false)
    minutes ||= 90
    court ||= 'ANY'
    court = COURTS[court.to_s.upcase] || court
    court = [COURT_5C, COURT_5D, COURT_6A, COURT_6B] if court.to_s.upcase == 'ALL'
    attempts = [COURT_5C, COURT_5D, COURT_6A, COURT_6B] if court.to_s.upcase == 'ANY'

    (hr, min) = start.split(':')
    start_time = central_time_at(days_offset: 7, hr: hr, min: min)
    end_time = start_time + (60 * minutes.to_i)

    (attempts || [court]).each do |c|
      data = {
        start_time: start_time.utc.iso8601,
        end_time: end_time.utc.iso8601,
        instantBook: true,
        courts: [c].flatten,
        userId: user_id,
        force: false,
        sport_id: '1',
        fullName: @user,
        assigned: [],
        tags: [],
        partners: [],
        guests: [],
        add_on_id: nil
      }

      puts "rattempt: #{Time.now}"
      puts "rrequest: #{data.to_json}"

      @response = if dry_run
                    BallButton.get('', headers: user_token_header)
                  else
                    BallButton.post(RESERVE_URL, body: data.to_json,
                                                 headers: user_token_header)
                  end
      return @response if @response.ok?
    end

    @response
  end
end

@bb = BallButton.new(ENV['BB_USER'])

if 'generate-schedule' == ARGV[0]
  puts @bb.generate_schedule
elsif 'reserve-today' == ARGV[0]
  responses = @bb.reserve_today.map { |r| r.parsed_response }
  puts "responses: #{responses}"
elsif 'cancel' == ARGV[0]
  result = @bb.cancel(ARGV[1], confirm_date: ARGV[2])
  puts "cancel response: #{result.respond_to?(:parsed_response) ? result.parsed_response : result}"
  puts @bb.generate_schedule
else
  response = @bb.reserve(
    ENV['RESERVE_START'],
    court: ENV['COURT'],
    dry_run: 'true' == ENV['DRY_RUN'],
    minutes: ENV['D']
  ).parsed_response

  puts "response: #{response}"
end
