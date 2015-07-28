require 'fileutils'
require 'logger'
require 'timeout'
require 'pry'
require_relative 'adb'

module MonkeyMaster
  # A class for conveniently employing Android adb monkeys.
  #
  # Author::    Lukas Nagl  (mailto:lukas.nagl@innovaptor.com)
  # Copyright:: Copyright (c) 2013 Innovaptor OG
  # License::   MIT
  class MonkeyCommander
    # Directory of the monkey logs.
    attr_reader :log_dir
    # Logger used for the monkey output.
    attr_reader :logger
    # The id of the app that should be tested by monkeys. E.g.: com.innovaptor.MonkeyTestApp
    attr_writer :app_id
    # The number of monkey iterations that should be run on each device.
    attr_writer :iterations
    # List of devices that should be used by the MonkeyCommander.
    attr_writer :device_list

    public

    # Initialize the monkey master.
    #
    # +app_id+:: The id of the app that should be tested by the monkeys, e.g. com.innovaptor.MonkeyTestApp
    def initialize(app_id)
      @app_id = app_id
      @iterations = 1 # Default to a single iteration
      @base_dir = Dir.pwd
      time = Time.new
      @log_dir = 'monkey_logs' + time.strftime('%Y%m%d_%H%M%S')
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        "#{severity}|#{datetime}: #{msg}\n"
      end
    end

    # Either create a list of devices from the parameter,
    # or detect connected devices using adb.
    #
    # +devices+:: nil, for automatic device detection; or a list of device IDs separated by ','
    def detect_devices(devices)
      @device_list = devices ? devices.split(',') : ADB.detect_devices
    end

    # Kill the monkey on all detected devices.
    def kill_monkeys
      ADB.kill_monkeys(@device_list)
    end

    # Start running monkeys on all specified devices.
    def command_monkeys
      if !@device_list || @device_list.empty?
        fail(ArgumentError, 'No devices found or specified. Check if development mode is on.')
      end

      fail(ArgumentError, 'No app id specified.') unless @app_id

      prepare

      masters = []
      begin
        @device_list.each do |device|
          master = Thread.new do
            # Monkey around in parallel

            device_log = log_for_device(@app_id, device)

            @logger.info("[MASTER #{device}] Starting to command monkeys.")
            @iterations.to_i.times do |i|
              @logger.info("\t[MASTER #{device}] Monkey #{i} is doing its thing…")

              # Start the monkey
              if ADB.monkey_run(@app_id, device) != 0
                @logger.info("\t\t[MASTER #{device}] Monkey encountered an error!")
              end

              # Archive and clean the log
              archive_and_clean_log(device_log, "monkeylog_#{device}_#{i}.txt")

              @logger.info("\t\t[MASTER #{device}] Monkey #{i} is killing the app now in preparation for the next monkey.")
              ADB.monkey_stop(@app_id, device)
            end
            @logger.info("[MASTER #{device}] All monkeys are done.")
          end
          masters.push(master)
        end

        masters.each(&:join) # wait for all masters to finish
      rescue SystemExit, Interrupt
        # Clean and graceful shutdown, if possible
        @logger.info('[MASTER] Received interrupt. Stopping all masters.')
        masters.each(&:terminate)
      end

      ADB.kill_monkeys(@device_list)
      ADB.end_logging(@device_list)
    end

    private

    def archive_and_clean_log(device_log, name)
      FileUtils.cp(device_log, File.join(@log_dir, name))
      File.truncate(device_log, 0)
    end

    # start monkey log for a certain device
    def log_for_device(app_id, device)
      log_device_name = "monkey_current#{device}.txt"
      log = File.join(@log_dir, log_device_name)
      ADB.start_logging(app_id, device, log)
      log
    end

    # Do all necessary preparations that are necessary for the monkeys to run.
    def prepare
      unless File.directory?(@log_dir)
        Dir.mkdir(@log_dir)
        @logger.info("[SETUP] Writing to the following folder: #{@log_dir}")
      end
      ADB.kill_monkeys(@device_list)
    end
  end
end
