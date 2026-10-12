require 'httparty'
require 'json'
require 'time'
require 'tzinfo'
require_relative 'history'

class BallButton
  include HTTParty

  COURT_5 = 1176
  COURT_5C = 1178
  COURT_5D = 1179
  COURT_6A = 1180
  COURT_6B = 1181
  API_URL  = '/api/v1'
  BASE_URL = 'https://balbuton.com'
  LOGIN_URL = "#{API_URL}/auth/login"
  BOOKING_URL = "#{API_URL}/appointment/get"
  CHECKIN_MEMBER_URL = "#{API_URL}/members_checkin/addcheckin"
  CHECKIN_LOCATION_URL = "#{API_URL}/checkin"
  LIST_URL = "#{API_URL}/members/booking"
  RESERVE_URL = "#{API_URL}/appointment/add_book"
  CANCEL_URL = "#{API_URL}/appointment/cancel"
  CHICAGO_TZ = TZInfo::Timezone.get('America/Chicago')
  CHECKIN_WINDOW_BEFORE_MIN = 60
  CHECKIN_WINDOW_AFTER_MIN = 150
  BOOKING_OPEN_HOUR_CENTRAL = 6
  BOOKING_OPEN_MAX_WAIT_SEC = 600
  REQUEST_MAX_ATTEMPTS = 3
  REQUEST_BACKOFF_BASE_SEC = 2

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

    location_response = checkin_location
    checkin_member(next_check_in.id) if location_response.ok?
    @bookings = nil
    note("checked in #{slot_label(Time.parse(next_check_in.start_time))}") if location_response.ok?
    location_response
  end

  def checkin_location(location_id: '134')
    request(:post,
      CHECKIN_LOCATION_URL,
      context: 'checkin_location',
      body: {location_id: location_id}.to_json,
      headers: user_token_header
    )
  end

  def checkin_member(booking_id)
    request(:post,
      "#{CHECKIN_MEMBER_URL}/#{booking_id}",
      context: 'checkin_member',
      body: {date: central_time_at, users: [user_id]}.to_json,
      headers: user_token_header
    )
  end

  def sync
    begin
      check_in_next
    rescue => e
      fail_note("check_in_next: #{e.message}")
    end

    History.replace_bookings(
      bookings.map do |booking|
        {
          id: booking.id,
          start_time: booking.start_time,
          end_time: booking.end_time,
          court: booking.court,
          checked_in: !(booking.checkins.nil? || booking.checkins.empty?)
        }
      end
    )
  end

  def begin_run(command)
    History.start_run(command, @user)
  end

  def finish_run(command, error: nil)
    failed = error || @failed
    summary = @notes&.join('; ')
    detail = [@details, error&.message&.slice(0, 500)].flatten.compact.join("\n")

    History.finish_run(
      status: failed ? 'error' : 'ok',
      summary: summary,
      detail: detail.empty? ? nil : detail
    )
  end

  def user_id
    USERS[@user]['id'].to_s
  end

  def user_token
    USERS[@user]['token']
  end

  def user_token_header
    { 'x-access-token': user_token }
  end

  # Exchanges the stored username/password for a fresh JWT. The response
  # also carries the account's password hash, FCM push token, email, and
  # home coordinates, so only the token is ever pulled out of it.
  def login
    response = call(:post,
      LOGIN_URL,
      context: 'login',
      redact: true,
      body: {
        username: USERS[@user]['username'],
        password: USERS[@user]['password'],
        front: true
      }.to_json
    )

    raise "login failed (status #{response.code})" unless response.ok?

    response.parsed_response.dig('payload', 'token') ||
      raise('login response missing payload.token')
  end

  def refresh_token!
    persist_token(login)
  end

  # Re-reads the file before writing so a concurrent cron run's refresh
  # isn't clobbered, and writes via rename so a run that crashes mid-write
  # can't leave the file truncated.
  def persist_token(token)
    path = "#{__dir__}/ball_button.users.json"
    current = JSON.parse(File.read(path))
    current[@user]['token'] = token

    tmp_path = "#{path}.tmp.#{Process.pid}"
    File.write(tmp_path, JSON.pretty_generate(current))
    File.rename(tmp_path, path)

    USERS[@user]['token'] = token
  end

  def bookings
    @bookings ||= begin
      list = fetch_booking_list

      list.map do |appt|
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
  end

  def booking(booking_id)
    url = "#{BOOKING_URL}/#{booking_id}"

    booking = request(:get, url, context: 'booking', headers: user_token_header).parsed_response['payload']

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

      unless confirm_date == actual_date
        fail_note("cancel #{apt_id}: not allowed")
        return 'not allowed'
      end
    end

    response = call(:post,
      "#{CANCEL_URL}/#{apt_id}",
      context: 'cancel',
      body: {cancel_for: 'court', apt_id: apt_id.to_s}.to_json,
      headers: user_token_header
    )
    response.ok? ? note("cancelled #{apt_id}") : fail_note("cancel #{apt_id}: #{response_message(response)}")
    response
  end

  def reserve_today
    weekday = central_time_at.strftime('%A').downcase
    entries = SCHEDULE[weekday] || []

    unless entries.empty?
      warm_token
      wait_for_booking_open
    end

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
    court_label = court.to_s.upcase == 'ANY' ? 'any court' : "court #{court}"
    court = COURTS[court.to_s.upcase] || court
    court = [COURT_5C, COURT_5D, COURT_6A, COURT_6B] if court.to_s.upcase == 'ALL'
    attempts = [COURT_5C, COURT_5D, COURT_6A, COURT_6B] if court.to_s.upcase == 'ANY'

    (hr, min) = start.split(':')
    start_time = central_time_at(days_offset: 7, hr: hr, min: min)
    end_time = start_time + (60 * minutes.to_i)
    slot = "#{slot_label(start_time, end_time)} #{court_label}"

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
                    call(:get, '', context: 'reserve', headers: user_token_header)
                  else
                    call(:post, RESERVE_URL, context: 'reserve', body: data.to_json,
                                             headers: user_token_header)
                  end
      detail("#{court_name(c)}: #{response_message(@response)}")
      return note_reservation(slot, dry_run) if @response.ok?
    end

    fail_note("#{'dry run ' if dry_run}failed to book #{slot}")
    @response
  end

  private

  def fetch_booking_list(context: 'bookings')
    data = {
      startDate: central_time_at.to_datetime.iso8601,
      endDate: central_time_at(days_offset: 7, hr: 23).to_datetime.iso8601,
      type: '0',
      is_coach: false
    }

    request(:post,
      "#{LIST_URL}/#{user_id}",
      context: context,
      body: data.to_json,
      headers: user_token_header
    ).parsed_response.dig('payload', 'bookings_history') || []
  end

  # Spends any 401 token refresh before the booking window opens.
  def warm_token
    fetch_booking_list(context: 'warmup')
  end

  def wait_for_booking_open
    open_at = central_time_at(hr: BOOKING_OPEN_HOUR_CENTRAL)
    remaining = open_at - Time.now
    return unless remaining.positive? && remaining <= BOOKING_OPEN_MAX_WAIT_SEC

    puts "reserve: waiting #{remaining.round(2)}s until bookings open at #{open_at}"
    sleep(remaining)
  end

  def note(text)
    (@notes ||= []) << text
  end

  def fail_note(text)
    @failed = true
    note(text)
  end

  def detail(text)
    (@details ||= []) << text
  end

  def note_reservation(slot, dry_run)
    note("#{'dry run ' if dry_run}booked #{slot}")
    @response
  end

  def court_name(court)
    [court].flatten.map { |id| COURTS.key(id) || id }.join(', ')
  end

  def slot_label(start_time, end_time = nil)
    from = CHICAGO_TZ.to_local(start_time)
    return from.strftime('%a %b %-d %-l:%M%P') unless end_time

    "#{from.strftime('%a %b %-d %-l:%M')}-#{CHICAGO_TZ.to_local(end_time).strftime('%-l:%M%P')}"
  end

  def response_message(response)
    parsed = response.parsed_response
    parsed.is_a?(Hash) && parsed['message'] ? parsed['message'] : "status #{response.code}"
  end

  # Records every API call to History. Login bodies are redacted - they carry
  # the password going out and credentials coming back.
  def call(method, url, context:, attempt: 1, redact: false, **options)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = error = nil

    begin
      response = BallButton.send(method, url, **options)
    rescue => e
      error = e
    end

    History.record_request(
      method: method,
      url: url,
      context: context,
      attempt: attempt,
      status: response&.code,
      duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
      request_body: redact ? nil : options[:body],
      response_body: redact ? nil : response&.body,
      error: error&.message
    )

    raise error if error

    response
  end

  # Retries idempotent GET/POST calls when the API returns a transient
  # failure (e.g. a 504 gateway timeout, which comes back as an HTML body
  # instead of JSON) so callers always get a parsed Hash back. Also
  # refreshes the token once on a 401 and retries with it - logins appear
  # to invalidate sibling sessions, so this only fires when the stored
  # token has actually gone stale, not on every run.
  def request(method, url, context:, **options)
    attempt = 1
    token_refreshed = false

    loop do
      response = call(method, url, context: context, attempt: attempt, **options)
      return response if response.ok? && response.parsed_response.is_a?(Hash)

      if !token_refreshed && response.code == 401 && options[:headers]
        token_refreshed = true
        refresh_token!
        options = options.merge(headers: user_token_header)
        next
      end

      if attempt >= REQUEST_MAX_ATTEMPTS
        raise "request failed after #{attempt} attempts: #{method.upcase} #{url} " \
              "(status #{response.code}): #{response.parsed_response.inspect}"
      end

      sleep(REQUEST_BACKOFF_BASE_SEC**attempt)
      attempt += 1
    end
  end
end

command = ARGV[0] || 'reserve'
@bb = BallButton.new(ENV['BB_USER'])

if 'record-failure' == command
  History.start_run(ARGV[1], ENV['BB_USER'])
  History.finish_run(status: 'error', summary: "exit #{ARGV[2]} - see cron log")
  exit
end

@bb.begin_run(command)

begin
  if 'sync' == command
    @bb.sync
  elsif 'reserve-today' == command
    responses = @bb.reserve_today.map { |r| r.parsed_response }
    puts "responses: #{responses}"
  elsif 'cancel' == command
    result = @bb.cancel(ARGV[1], confirm_date: ARGV[2])
    puts "cancel response: #{result.respond_to?(:parsed_response) ? result.parsed_response : result}"
    @bb.sync
  elsif 'login' == command
    @bb.refresh_token!
    puts 'login: token refreshed and saved'
  else
    response = @bb.reserve(
      ENV['RESERVE_START'],
      court: ENV['COURT'],
      dry_run: 'true' == ENV['DRY_RUN'],
      minutes: ENV['D']
    ).parsed_response

    puts "response: #{response}"
  end
rescue => e
  @bb.finish_run(command, error: e)
  raise
end

@bb.finish_run(command)
