require "./src/cron_parser"

cron_parser = CronParser.new("30 * * * *")

# Comming times
p cron_parser.next(Time.now)
p cron_parser.next(Time.now, 5)

p cron_parser.next(Time.utc_now)
p cron_parser.next(Time.utc_now, 5)

# Times that have been
p cron_parser.last(Time.now)
p cron_parser.last(Time.now, 5)
