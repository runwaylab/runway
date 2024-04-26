class CronParser
  VERSION = "0.4.0"

  class InternalTime
    property year : Int32
    property month : Int32
    property day : Int32
    property hour : Int32
    property min : Int32
    property second : Int32
    property location : Time::Location

    def initialize(time)
      @year = time.year
      @month = time.month
      @day = time.day
      @hour = time.hour
      @min = time.minute
      @second = time.second
      @location = time.location
    end

    def to_time
      Time.local(@year, @month, @day, @hour, @min, @second, nanosecond: 0, location: @location)
    end
  end

  @source : String
  @time_specs : TimeSpec

  def initialize(source)
    @source = interpret_vixieisms(source.strip)
    @_interpolate_weekdays_cache = {} of Tuple(Int32, Int32) => Array(Int32)
    validate_source
    @time_specs = calc_time_spec
  end

  # returns the next occurence after the given date
  def next(now = Time.local)
    t = InternalTime.new(now)

    unless time_specs.month.values.includes?(t.month)
      nudge_month(t)
      t.day = 0
    end

    unless interpolate_weekdays(t.year, t.month).includes?(t.day)
      nudge_date(t)
      t.hour = -1
    end

    unless time_specs.hour.values.includes?(t.hour)
      nudge_hour(t)
      t.min = -1
    end

    unless time_specs.second
      nudge_minute(t)
      t.second = 0
    else
      unless time_specs.minute.values.includes?(t.min)
        nudge_minute(t)
        t.second = -1
      end

      nudge_second(t)
    end

    t.to_time
  end

  # returns the last occurence before the given date
  def last(now = Time.local)
    t = InternalTime.new(now)

    unless time_specs.month.values.includes?(t.month)
      nudge_month(t, :last)
      t.day = 32
    end

    if t.day == 32 || !interpolate_weekdays(t.year, t.month).includes?(t.day)
      nudge_date(t, :last)
      t.hour = 24
    end

    unless time_specs.hour.values.includes?(t.hour)
      nudge_hour(t, :last)
      t.min = 60
    end

    unless time_specs.second
      nudge_minute(t, :last)
      t.second = 0
    else
      unless time_specs.minute.values.includes?(t.min)
        nudge_minute(t, :last)
        t.second = 60
      end

      nudge_second(t, :last)
    end

    t.to_time
  end

  macro array_result(name)
    def {{ name.id }}(now : Time, num : Int32)
      res = [] of Time
      n = self.{{ name.id }}(now)
      res << n
      (num - 1).times do
        n = self.{{ name.id }}(n)
        res << n
      end
      res
    end
  end

  array_result :next
  array_result :last

  SUBELEMENT_REGEX = %r{^(\d+)(-(\d+)(/(\d+))?)?$}

  record Element, values : Set(Int32), values_a : Array(Int32), elem : String

  def parse_element(elem, allowed_range)
    values = elem.split(",").map do |subel|
      if subel =~ /^\*/
        step = subel.size > 1 ? subel[2..-1].to_i : 1
        stepped_range(allowed_range, step, allowed_range)
      else
        if m = subel.match(SUBELEMENT_REGEX)
          if m[5]? # with range
            stepped_range(m[1].to_i..m[3].to_i, m[5].to_i, allowed_range)
          elsif m[3]? # range without step
            stepped_range(m[1].to_i..m[3].to_i, 1, allowed_range)
          else # just a numeric
            [m[1].to_i]
          end
        else
          raise ArgumentError.new("Bad Vixie-style specification #{subel}")
        end
      end
    end.flatten.sort

    Element.new(Set.new(values), values.sort, elem)
  end

  # protected

  # returns a list of days which do both match time_spec[:dom] or time_spec[:dow]
  private def interpolate_weekdays(year, month)
    @_interpolate_weekdays_cache[{year, month}] ||= interpolate_weekdays_without_cache(year, month)
  end

  private def interpolate_weekdays_without_cache(year, month)
    t = Time.local(year, month, 1)
    valid_mday, mday_field = time_specs.dom.values, time_specs.dom.elem
    valid_wday, wday_field = time_specs.dow.values, time_specs.dow.elem

    # Careful, if both DOW and DOM fields are non-wildcard,
    # then we only need to match *one* for cron to run the job:
    if !(mday_field == "*" && wday_field == "*")
      valid_mday.clear if mday_field == "*"
      valid_wday.clear if wday_field == "*"
    end

    # Careful: crontabs may use either 0 or 7 for Sunday:
    valid_wday << 0 if valid_wday.includes?(7)

    result = [] of Int32

    while t.month == month
      wday = t.day_of_week.to_i
      wday = 0 if wday == 7
      result << t.day if valid_mday.includes?(t.day) || valid_wday.includes?(wday)
      t += 1.day
    end

    result.sort
  end

  private def nudge_year(t, dir = :next)
    t.year += (dir == :next) ? 1 : -1
  end

  private def nudge_month(t, dir = :next)
    spec = time_specs.month.values_a
    next_value = find_best_next(t.month, spec, dir)
    t.month = next_value || (dir == :next ? spec.first : spec.last)

    nudge_year(t, dir) unless next_value

    # we changed the month, so its likely that the date is incorrect now
    valid_days = interpolate_weekdays(t.year, t.month)
    t.day = (dir == :next) ? valid_days.first : valid_days.last
  end

  private def nudge_date(t, dir = :next, can_nudge_month = true)
    spec = interpolate_weekdays(t.year, t.month)
    next_value = find_best_next(t.day, spec, dir)
    t.day = next_value || (dir == :next ? spec.first : spec.last)

    nudge_month(t, dir) if next_value.nil? && can_nudge_month
  end

  private def nudge_hour(t, dir = :next)
    spec = time_specs.hour.values_a
    next_value = find_best_next(t.hour, spec, dir)
    t.hour = next_value || (dir == :next ? spec.first : spec.last)

    nudge_date(t, dir) if next_value.nil?
  end

  private def nudge_minute(t, dir = :next)
    spec = time_specs.minute.values_a
    next_value = find_best_next(t.min, spec, dir)
    t.min = next_value || (dir == :next ? spec.first : spec.last)

    nudge_hour(t, dir) if next_value.nil?
  end

  private def nudge_second(t, dir = :next)
    if second = time_specs.second
      spec = second.values_a
      next_value = find_best_next(t.second, spec, dir)
      t.second = next_value || (dir == :next ? spec.first : spec.last)

      nudge_minute(t, dir) if next_value.nil?
    end
  end

  record TimeSpec, minute : Element, hour : Element, dom : Element, month : Element, dow : Element do
    property second : Element?
  end

  private def calc_time_spec
    # tokens now contains the 5 fields
    tokens = substitute_parse_symbols(@source).split(/\s+/)

    # if tokens has 6 parts, we parse first one as seconds (EXTRA syntax)
    second = if tokens.size == 6
               tokens.shift
             end

    res = TimeSpec.new(
      parse_element(tokens[0], 0..59), # minute
      parse_element(tokens[1], 0..23), # hour
      parse_element(tokens[2], 1..31), # DOM
      parse_element(tokens[3], 1..12), # mon
      parse_element(tokens[4], 0..6),  # DOW
    )

    if second
      res.second = parse_element(second, 0..59) # second [optional]
    end

    res
  end

  SYMBOLS = {
    "jan" => "1",
    "feb" => "2",
    "mar" => "3",
    "apr" => "4",
    "may" => "5",
    "jun" => "6",
    "jul" => "7",
    "aug" => "8",
    "sep" => "9",
    "oct" => "10",
    "nov" => "11",
    "dec" => "12",

    "sun" => "0",
    "mon" => "1",
    "tue" => "2",
    "wed" => "3",
    "thu" => "4",
    "fri" => "5",
    "sat" => "6",
  }

  private def substitute_parse_symbols(str)
    s = str.downcase
    SYMBOLS.each do |from, to|
      s = s.gsub(from, to)
    end
    s
  end

  private def stepped_range(rng, step, allowed_range)
    first = rng.begin
    last = rng.end
    first = allowed_range.begin if first < allowed_range.begin
    last = allowed_range.end if last > allowed_range.end
    len = last - first

    num = len./(step)
    result = (0..num).map { |i| first + step * i }

    result.pop if result[-1] == last && rng.exclusive?
    result
  end

  # returns the smallest element from allowed which is greater than current
  # returns nil if no matching value was found
  private def find_best_next(current, allowed, dir)
    if dir == :next
      allowed.each { |val| return val if val > current }
    else
      allowed.reverse_each { |val| return val if val < current }
    end
    nil
  end

  private def validate_source
    unless @source.responds_to?(:split)
      raise ArgumentError.new("not a valid cronline")
    end
    source_length = @source.split(/\s+/).size
    unless source_length >= 5 && source_length <= 6
      raise ArgumentError.new("not a valid cronline")
    end
  end

  private def interpret_vixieisms(spec)
    case spec
    when "@reboot"
      raise ArgumentError.new("Can't predict last/next run of @reboot")
    when "@yearly", "@annually"
      "0 0 1 1 *"
    when "@monthly"
      "0 0 1 * *"
    when "@weekly"
      "0 0 * * 0"
    when "@daily", "@midnight"
      "0 0 * * *"
    when "@hourly"
      "0 * * * *"
    else
      spec
    end
  end

  private def time_specs
    @time_specs
  end
end
