require 'ostruct'
require 'optparse'
require 'open-uri'
require 'json'
require 'holidays'

USAGE = "Usage: #{$0} [OPTION ...]"

SECS_PER_DAY = 24*60*60
MAIL_SUBJECT = "stale dataset report"

@options = OpenStruct.new(
  :site => "data.austintexas.gov",
  :id => nil,
  :max_days => 5,
  :notify => [],
  :verbose => false,
  :mail_command => "mailx"
)

def die(mssg)
  case mssg
  when :USAGE
    $stderr.puts("#{USAGE} (try \"--help\" for help)")
  else
    $stderr.puts("#{$0}: #{mssg}")
  end
  exit(1)
end

class NilClass
  # so "nil.empty?" works
  def empty?
    true
  end
end


class Report

  def initialize(options = {})
    @verbose = !!options[:verbose]
    @report = []
  end

  def <<(s)
    puts s if @verbose
    @report << s
  end

  def add(name, value, addl = nil)
    s = sprintf("%-16s", name + ":") + value.to_s
    s << " " + addl unless addl.empty?
    self << s
  end

  def to_s
    @report.join("\n") + "\n"
  end

end # Report


OptionParser.new do |opts|

  opts.banner = USAGE
  opts.separator ""
  opts.separator "Options:"

  opts.on("-iID", "--id=ID", "Data set id -- this is required") do |id|
    @options.id = id
  end

  opts.on("-sSITE", "--site=SITE", "Data portal hostname [default: #{@options.site}]") do |site|
    @options.site = site
  end

  opts.on("-mDAYS", "--maxdays=DAYS", "Dataset older than this number of business days considered stale [default: #{@options.max_days}]") do |days|
    @options.max_days = days
  end

  opts.on("-nEMAIL", "--notify=EMAIL", "Send report to this email address if dataset stale, repeat option for each recipient") do |email|
    @options.notify << email
  end

  opts.on("-v", "--verbose", "Display report created during processing") do
    @options.verbose = true
  end

  opts.on("-MCMD", "--mailer=CMD", "Use this program to send mail [default: #{@options.mail_command}]") do |cmd|
    @options.mail_command = cmd
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

die(:USAGE) unless ARGV.empty?
die("dataset id (--id) not specified") if @options.id.empty?


@report = Report.new(:verbose => @options.verbose)
@report.add("Dataset Id", @options.id)

@endpoint = "https://#{@options.site}/api/views/#{@options.id}"
@report.add("Endpoint", @endpoint)

# Retrieve metadata for dataset
meta = {}
open(@endpoint) do |f|
  data = f.read
  meta = JSON.parse(data)
end
@report.add("Name", meta["name"])

die "unable to retrieve \"rowsUpdatedAt\" value" unless meta.has_key?("rowsUpdatedAt")
last_update = Time.at(meta["rowsUpdatedAt"])
@report.add("Last updated", last_update)

age_calendar_days = (Time.now - last_update) / SECS_PER_DAY
@report.add("Dataset age", sprintf("%.1f", age_calendar_days), "(calendar days)")

# Count weekend days and holidays from when dataset was last updated to now.
non_business_days = (last_update.to_date .. Time.now.to_date) \
  .to_a \
  .select {|d| d.saturday? || d.sunday? || d.holiday?(:us)} \
  .count

age_business_days = age_calendar_days - non_business_days
@report.add("Dataset age", sprintf("%.1f", age_business_days), "(business days)")
@report.add("Max age", sprintf("%.1f", @options.max_days), "(business days)")

is_stale = (age_business_days > @options.max_days.to_f)
dataset_status = (is_stale ? "STALE" : "CURRENT")
@report.add("Dataset status", dataset_status)
unless @options.verbose
  puts "Dataset is #{dataset_status}"
end

if is_stale && ! @options.notify.empty?
  puts "Notifying #{@options.notify.join(', ')} ..."
  subj = "#{MAIL_SUBJECT} [#{meta['name']}]"
  cmd = [@options.mail_command, "-s", subj] + @options.notify
  IO.popen(cmd, "w") do |f|
    f.puts @report.to_s
  end
end

