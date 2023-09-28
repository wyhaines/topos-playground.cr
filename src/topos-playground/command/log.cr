require "parse_date"
require "../command"

class ToposPlayground::Command::Logs < ToposPlayground::Command
  UUID_REGEXP = /([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})/

  def self.options(parser, config)
    parser.on("log", "List, View, and Prune topos-playground logs") do
      config.command = "logs"
      parser.separator("\nLog commands:")

      list_options(parser, config)
      view_options(parser, config)
      prune_options(parser, config)
    end
  end

  def self.list_options(parser, config)
    parser.on("list", "Show all of the log files that currently exist in the log directory") do
      config.subcommand = "list"
    end
  end

  def self.view_options(parser, config)
    parser.on("view", "View a topos-playground log file. With no other flags, this defaults to the most recent log file.") do
      config.subcommand = "view"
      parser.separator("\nLog View options:")
      parser.on("-i [POSITION]", "--index [POSITION]", "View the log file at position POSITION, starting with the most recent log file and counting backwards. Defaults to 1, which means the most recent log file.") do |position|
        position = 1 if position.empty?
        config.parameter = "index:#{position}"
      end
      parser.on("-b [DATE/TIME]", "--before [DATE/TIME]", "View the log file before the specified date/time. Defaults to the most recent log file.") do |date_time|
        config.parameter = "before:#{date_time}"
      end
      parser.on("-a [DATE/TIME]", "--after [DATE/TIME]", "View the log file after the specified date/time. Defaults to the oldest log file.") do |date_time|
        config.parameter = "after:#{date_time}"
      end
      parser.separator("\nBe aware that this version of the playground will make a best-effort to properly sort log files, but if log files created with this version of the playground are mixed with log files from the Node.js version (which are not timestamped in the same way), unexpected results may occur.")
    end
  end

  def self.prune_options(parser, config)
    parser.on("prune", "Prune log files from the log directory") do
      config.subcommand = "prune"
      parser.separator("\nLog Prune options:")
      parser.on("-n", "--dry-run", "Do not actually delete any files. Just show what would be deleted.") do
        config.dry_run = true
      end
      parser.on("-d [DAYS]", "--days [DAYS]", "Prune log files older than DAYS days. Defaults to 7 days.") do |days|
        days = 7 if days.empty?
        config.parameter = "days:#{days}"
      end
      parser.on("-s [SIZE]", "--size [SIZE]", <<-EDESC) do |size|
        Prune log files smaller than SIZE bytes. Defaults to 1024 bytes.
        Numbers can be suffixed to indicate units.
            2048
            2048b   2048 bytes
            10k
            10kb    10 kilobytes
            1m
            1mb     1 megabyte
            4g
            4gb     4 gigabytes
        EDESC
        size = 1024 if size.empty?
        config.parameter = "size:#{size}"
      end
      parser.on("-r [RANGE]", "--range [RANGE]", <<-EDESC) do |range|
        Prune log files within a given range. Files are numbered in the same manner as with the `list` command or the `view --index` command, with the most recent log file being at position 1.
        Range syntax is as follows:
            10..15  files 10 through 15
            ..5     the 5 most recent files; i.e. files 1 to 5
            6..     all files, starting with the 6th most recent file
            ..      this would be the same as the `--all` flag

        Specific files can also be specified by number, either alone, or in a comma separated list.
            39      the 39th most recent file
            3,5,7   the 3rd, 5th, and 7th most recent files
        EDESC
        unless range.empty?
          config.parameter = "range:#{range}"
        end
      end
      parser.on("-a", "--all", "Prune all log files.") do
        config.parameter = "all"
      end
    end
  end

  def run
    case config.subcommand?
    when "list"
      do_list
    when "view"
      do_view
    when "prune"
      do_prune
    end
  end

  def do_list
    log_sort(handle_erroneously_old_logs(generate_base_list)).tap do |logs|
      print_logs(
        handle_erroneously_young_logs(
          logs,
          *calculate_gaps_and_standard_deviation(logs)))
    end
  end

  def do_view
    config.parameter = "index:1" unless config.parameter?
    operation, selector = config.parameter?.to_s.split(":", 2)

    log_sort(handle_erroneously_old_logs(generate_base_list)).tap do |logs|
      sorted_logs = handle_erroneously_young_logs(
        logs,
        *calculate_gaps_and_standard_deviation(logs))

      case operation
      when "index"
        do_view_index(sorted_logs, selector)
      when "before"
        do_view_before(sorted_logs, selector)
      when "after"
        do_view_after(sorted_logs, selector)
      end
    end
  end

  def do_view_index(sorted_logs, selector)
    selector = selector.to_s.to_i { 0 } < 1 ? 1 : selector.to_s.to_i
    selector = sorted_logs.size if selector > sorted_logs.size

    show_log_file(sorted_logs[-selector])
  end

  def do_view_before(sorted_logs, selector)
    selector = Time.local if selector.to_s.empty?
    limit_date = ParseDate.parse(selector.to_s)

    if limit_date
      log = sorted_logs.reverse.find { |_log| _log[2] < limit_date }
      show_log_file(log) if log
    end
  end

  def do_view_after(sorted_logs, selector)
    selector = Time.unix(0).to_s if selector.to_s.empty?
    limit_date = ParseDate.parse(selector.to_s)

    if limit_date
      log = sorted_logs.find { |_log| _log[2] > limit_date }
      show_log_file(log) if log
    end
  end

  def do_prune
    config.parameter = "index:1" unless config.parameter?
    operation, selector = config.parameter?.to_s.split(":", 2)

    log_sort(handle_erroneously_old_logs(generate_base_list)).tap do |logs|
      sorted_logs = handle_erroneously_young_logs(
        logs,
        *calculate_gaps_and_standard_deviation(logs))

      case operation
      when "days"
        do_prune_days(sorted_logs, selector)
      when "size"
        do_prune_size(sorted_logs, selector)
      when "range"
        do_prune_range(sorted_logs, selector)
      end
    end
  end

  def do_prune_days(sorted_logs, selector)
    selector = selector.to_s.to_i { 0 } <= 0 ? 0 : selector.to_s.to_i
    beginning_of_day = Time.local.at_beginning_of_day
    threshold = beginning_of_day - Time::Span.new(seconds: selector * 24 * 60 * 60)
    sorted_logs.each do |log|
      if log[2] < threshold
        if config.dry_run?
          puts "Would delete #{log[1]}"
        else
          File.delete(log[1])
        end
      end
    end
  end

  def do_prune_size(sorted_logs, selector)
    selector = parse_to_size(selector)
    puts "deleting less than #{selector} bytes"
    sorted_logs.each do |log|
      if File.info(log[1]).size < selector
        if config.dry_run?
          puts "Would delete #{log[1]}"
        else
          File.delete(log[1])
        end
      end
    end
  end

  def parse_to_size(selector)
    parts = /^\s*(\d+)\s*([bBkKmMgG]*)/.match(selector.to_s)
    return 1024 if parts.nil?

    number_part = parts[1].to_i?
    return 1024 unless number_part

    unit_part = parts[2]? ? parts[2].downcase : "b"

    case unit_part
    when "b"
      number_part.to_i
    when "k", "kb"
      number_part.to_i * 1024
    when "m", "mb"
      number_part.to_i * 1024 * 1024
    when "g", "gb"
      number_part.to_i * 1024 * 1024 * 1024
    else
      number_part
    end
  end

  def do_prune_range(sorted_logs, selector)
    range_parts = /^\s*(\d*)\s*\.\.\s*(\d*)\s*$/.match(selector.to_s)
    if range_parts
      start = range_parts[1].to_i? ? range_parts[1].to_i : 0
      finish = range_parts[2].to_i? ? range_parts[2].to_i : sorted_logs.size - 1

      if start > finish
        start, finish = finish, start
      end

      sorted_logs.reverse[start..finish].each do |log|
        if config.dry_run?
          puts "Would delete #{log[1]}"
        else
          File.delete(log[1])
        end
      end
    else
      selector.split(",").each do |index|
        index = index.to_i?
        if index && index > 0 && index <= sorted_logs.size
          log = sorted_logs[-index]
          if config.dry_run?
            puts "Would delete #{log[1]}"
          else
            File.delete(log[1])
          end
        end
      end
    end
  end

  # -----

  def show_log_file(log)
    puts log[1].center(ToposPlayground.terminal_width).colorize(:green)
    puts "-------".center(ToposPlayground.terminal_width).colorize(:green)
    puts File.read(log[1])
  end

  def log_sort(logs)
    logs.sort_by { |log| log[2] }
  end

  def generate_base_list : Array(Tuple(String, String, Time))
    files = Dir["#{config.log_dir.as(String)}/**"]
    files.compact_map do |file|
      if match = UUID_REGEXP.match(file)
        begin
          {match[1], file, CSUUID.new(match[1]).timestamp}
        rescue
          {match[1], file, File.info(file).modification_time}
        end
      end
    end
  end

  def handle_erroneously_old_logs(logs) : Array(Tuple(String, String, Time))
    # Anything with a prefix larger than this must be a log file from the Node.js version of the playground.
    current_prefix = CSUUID.new.to_s[0..7]

    logs.compact_map do |log|
      if log[0][0..7] > current_prefix
        {log[0], log[1], File.info(log[1]).modification_time}
      else
        log
      end
    end
  end

  def calculate_gaps_and_standard_deviation(logs)
    sum = 0_i128
    gaps = [] of Int64

    n = logs.size - 1
    while n > 0
      gap = (logs[n][2] - logs[n - 1][2]).to_i
      sum += gap
      gaps << gap
      n -= 1
    end

    average = sum / gaps.size

    # ameba:disable Lint/ShadowingOuterLocalVar
    sum_of_squared_differences = gaps.reduce(0_i128) { |sum, length| sum + (length - average)**2 }
    standard_deviation = Math.sqrt(sum_of_squared_differences / gaps.size)

    {gaps, standard_deviation}
  end

  def handle_erroneously_young_logs(logs, gaps, standard_deviation)
    logs.map_with_index do |log, index|
      if gaps[index]? && gaps[index] > standard_deviation * 2
        {log[0], log[1], File.info(log[1]).modification_time}
      else
        log
      end
    end.compact
  end

  def print_logs(logs)
    print_header(logs)

    log_sort(logs).each_with_index do |log, index|
      line = if single_line_size(log) > ToposPlayground.terminal_width
               multi_line(log, logs.size - index)
             else
               single_line(log, logs.size - index)
             end
      puts ToposPlayground.break_text(
        line,
        ToposPlayground.terminal_width
      )
    end
  end

  def print_header(logs)
    header = if single_line_size(logs.first) > ToposPlayground.terminal_width
               multi_line_header(logs)
             else
               single_line_header(logs)
             end

    puts ToposPlayground.break_text(
      header,
      ToposPlayground.terminal_width
    )
  end

  def single_line_header(logs)
    String.build do |str|
      str << " #".ljust(7)
      str << log_file_path_header.center(logs.first[1].size)
      str << " " * file_to_date_delimiter.size
      str << log_file_date_header.center(log_file_date(logs.first).size)
      str << " " * date_to_size_delimiter.size
      str << log_file_size_header.center(10)
    end
  end

  def multi_line_header(logs)
    String.build do |str|
      str << " #".ljust(7)
      str << log_file_path_header.center(logs.first[1].size).rstrip
      str << "\n"
      str << " " * short_file_to_date_delimiter.size
      str << log_file_date_header.center(log_file_date(logs.first).size)
      str << " " * date_to_size_delimiter.size
      str << log_file_size_header.center(10)
    end
  end

  def log_file_path_header
    "Log File Path"
  end

  def log_file_date_header
    "File Date"
  end

  def log_file_size_header
    "File Size"
  end

  def log_file_path(log)
    log[1]
  end

  def file_to_date_delimiter
    "    ->    "
  end

  def short_file_to_date_delimiter
    "    ->  "
  end

  def log_file_date(log)
    log[2].to_s.ljust(30)
  end

  def date_to_size_delimiter
    "  :  "
  end

  def single_line_size(log)
    7 + log_file_path(log).size + file_to_date_delimiter.size + log_file_date(log).size + 12
  end

  def log_file_size(log)
    File.info(log_file_path(log)).size.humanize_bytes
  end

  def format_index(index)
    "#{index.to_s.ljust(5)}) "
  end

  def single_line(log, index)
    String.build do |str|
      str << format_index(index)
      str << log_file_path(log)
      str << file_to_date_delimiter
      str << log_file_date(log)
      str << date_to_size_delimiter
      str << log_file_size(log)
    end
  end

  def multi_line(log, index)
    String.build do |str|
      str << format_index(index)
      str << log_file_path(log)
      str << "\n"
      str << short_file_to_date_delimiter
      str << log_file_date(log)
      str << date_to_size_delimiter
      str << log_file_size(log)
    end
  end
end
