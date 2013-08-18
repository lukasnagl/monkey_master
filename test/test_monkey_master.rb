require 'test/unit'
require 'monkey_master'

class MonkeyCommanderTest < Test::Unit::TestCase
	# Test the kill option in case no devices are connected
	def test_kill_no_devices
		assert_nothing_raised do
			commander = MonkeyMaster::MonkeyCommander.new("com.test.Example")
			commander.kill_monkeys
		end
	end

	# Test the kill option with a list of invalid devices
	def test_kill_invalid_devices
		assert_nothing_raised do
			commander = MonkeyMaster::MonkeyCommander.new("com.test.Example")
			commander.device_list = ["80123","34555"]
			commander.kill_monkeys
		end
	end

	# Test trying regular execution in case no devices are connected
	def test_command_no_devices
		assert_raise ArgumentError do
			commander = MonkeyMaster::MonkeyCommander.new("com.test.Example")
			# no devices
			commander.command_monkeys
		end
	end

	# Test trying regular execution with an invalid app id
	def test_command_no_app_id
		assert_raise ArgumentError do
			commander = MonkeyMaster::MonkeyCommander.new(nil)
			commander.device_list = ["80123","34555"]
			# no app id
			commander.command_monkeys
		end
	end

	# Test trying regular execution when invalid devices are given
	def test_command_invalid_devices
		assert_raise ArgumentError do
			commander = MonkeyMaster::MonkeyCommander.new("com.test.Example")
			commander.device_list = ["80123","34555"]
			# invalid devices, should raise an exception
			commander.command_monkeys
		end
	end
end