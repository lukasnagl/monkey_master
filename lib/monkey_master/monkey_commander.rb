require 'fileutils'
require 'logger'
require 'timeout'

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
      if devices
        # Devices are given, create a list
        devices = devices.split(',')
        @device_list = devices
      else
        # No devices specified, detect them
        device_list = `adb devices | grep -v "List" | grep "device" | awk '{print $1}'`
        device_list = device_list.split("\n")
        @device_list = device_list
      end
    end

    # Kill the monkey on each device.
    def kill_monkeys
      unless @device_list
        @logger.warn('[CLEANUP] No devices specified yet.')
        return
      end

      @device_list.each do |device|
        @logger.info('[CLEANUP] KILLING the monkey on device #{device}.')
        `adb -s #{device} shell ps | awk '/com\.android\.commands\.monkey/ { system("adb -s #{device} shell kill " $2) }'`
      end
    end

    # Start running monkeys on all specified devices.
    def command_monkeys
      if !@device_list || @device_list.empty?
        fail(ArgumentError, 'No devices found or specified.')
      end

      fail(ArgumentError, 'No app id specified.') unless @app_id

      prepare

      masters = []
      begin
        @device_list.each do |device|
          master = Thread.new do
            # Monkey around in parallel

            log_device_name = "monkey_current#{device}.txt"
            current_log = File.join(@log_dir, log_device_name)
            start_logging(device, current_log)
            @logger.info("[MASTER #{device}] Starting to command monkeys.")
            @iterations.to_i.times do |i|
              @logger.info("\t[MASTER #{device}] Monkey #{i} is doing its thing…")

              # Start the monkey
              `adb -s #{device} shell monkey -p #{@app_id} -v 80000 --throttle 100 --ignore-timeouts --pct-majornav 10 --pct-appswitch 0 --kill-process-after-error`
              if $?.exitstatus != 0
                @logger.info("\t\t[MASTER #{device}] Monkey encountered an error!")
              end

              # Archive the log
              log_archiving_name = "monkeylog_#{device}_#{i}.txt"
              FileUtils.cp(current_log, File.join(@log_dir, log_archiving_name))

              # Clean the current log
              File.truncate(current_log, 0)
              @logger.info("\t\t[MASTER #{device}] Monkey #{i} is killing the app now in preparation for the next monkey.")
              `adb -s #{device} shell am force-stop #{@app_id}`
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

      kill_monkeys
      end_logging
    end

    private

    # Do all necessary preparations that are necessary for the monkeys to run.
    def prepare
      unless File.directory?(@log_dir)
        Dir.mkdir(@log_dir)
        @logger.info("[SETUP] Writing to the following folder: #{@log_dir}")
      end
      kill_monkeys
    end

    # Start logging on all devices.
    def start_logging(device, current_log)
      begin
        timeout(5) do
          @logger.info("[SETUP] Creating the following log file: #{current_log}")
          `adb -s #{device} logcat -c #{current_log} &`
          `adb -s #{device} logcat *:W > #{current_log} &`
        end
      rescue Timeout::Error
        end_logging
        raise ArgumentError, 'It doesn’t seem like there are ready, connected devices.'
      end
    end

    # End logging on all devices.
    def end_logging
      @device_list.each do |device|
        @logger.info("[CLEANUP] KILLING the logcat process on device #{device}.")
        `adb -s #{device} shell ps | grep -m1 logcat | awk '{print $2}' | xargs adb -s #{device} shell kill`
        @logger.info("[CLEANUP] KILLING the logcat process for the device #{device} on the machine.")
        `ps ax | grep -m1 "adb -s #{device} logcat" | awk '{print $1}' | xargs kill`
      end
    end
  end
end
