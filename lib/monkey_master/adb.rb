require 'mkmf'

module MonkeyMaster
  # Provide helpers to work with Android ADB
  class ADB
    # Run the adb monkey.
    #
    # +app_id+:: ID of the android app for which the monkey should be run
    # +device+:: Device on which the adb monkey should be run
    # +args+:: Arguments passed to the adb monkey
    def self.monkey_run(app_id, device, args='-v 80000 --throttle 100 --ignore-timeouts --pct-majornav 10 --pct-appswitch 0 --kill-process-after-error')
      `adb -s #{device} shell monkey -p #{app_id} #{args}`
      $?.exitstatus
    end

    # Force stop a monkey for an app.
    #
    # +app_id+:: ID of the android app for which the monkey should be stopped
    def self.monkey_stop(app_id)
      `adb -s #{device} shell am force-stop #{app_id}`
    end

    # Use ADB to detect connected Android devices.
    def self.detect_devices
      device_list = `adb devices | grep -v "List" | grep "device" | awk '{print $1}'`
      device_list.split("\n")
    end

    # Kill ADB monkeys.
    #
    # +device+:: Devices for which the adb monkey should be killed
    def self.kill_monkeys(devices)
      unless devices
        puts '[ADB] No devices specified yet.'
        return
      end

      devices.each do |device|
        puts '[ADB] KILLING the monkey on device #{device}.'
        `adb -s #{device} shell ps | awk '/com\.android\.commands\.monkey/ { system("adb -s #{device} shell kill " $2) }'`
      end
    end

    # Start logging on a certain device with logcat
    #
    # +device+:: Device for which logging should be started
    # +log+:: File that should be used for logging
    def self.start_logging(device, log)
      begin
        timeout(5) do
          puts "[ADB/LOGS] Logging device #{device} to #{log}."
          `adb -s #{device} logcat -c #{log} &`
          `adb -s #{device} logcat *:W > #{log} &`
        end
      rescue Timeout::Error
        end_logging
        raise ArgumentError, 'It doesn’t seem like there are ready, connected devices.'
      end
    end

    # End logging on multiple devices.
    #
    # +device+:: Devices for which logging should be stopped
    def self.end_logging(devices)
      devices.each do |device|
        puts "[ADB/LOGS] KILLING the logcat process on device #{device}."
        `adb -s #{device} shell ps | grep -m1 logcat | awk '{print $2}' | xargs adb -s #{device} shell kill`
        puts "[ADB/LOGS] KILLING the logcat process for the device #{device} on the machine."
        `ps ax | grep -m1 "adb -s #{device} logcat" | awk '{print $1}' | xargs kill`
      end
    end

    # Check if adb is accessible as an executable
    def self.adb?
      adb = find_executable 'adb'
      adb.nil? ? false : true
    end
  end
end
