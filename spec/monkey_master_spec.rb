require 'spec_helper'

describe MonkeyMaster::MonkeyCommander do
  let(:device_stubs) { %w(80123 34555) }

  before do
    allow(MonkeyMaster::ADB).to receive(:monkey_run) { 0 }
    allow(MonkeyMaster::ADB).to receive(:monkey_stop) { `echo 'testing'` }
    allow(MonkeyMaster::ADB).to receive(:detect_devices) { %w(42 43) }
    allow(MonkeyMaster::ADB).to receive(:kill_monkeys) { %w(42 43) }
    allow(MonkeyMaster::ADB).to receive(:start_logging) { nil }
    allow(MonkeyMaster::ADB).to receive(:end_logging) { nil }
  end

  context 'killing monkeys' do
    let(:commander) { MonkeyMaster::MonkeyCommander.new('com.test.Example') }

    describe 'invalid device ids are given' do
      before { commander.device_list = device_stubs }

      it 'should be able to call the kill command' do
        expect { commander.kill_monkeys }.not_to raise_error
      end
    end

    describe 'when no devices are configured' do
      it 'should be able to call the kill command' do
        expect { commander.kill_monkeys }.not_to raise_error
      end
    end
  end

  context 'commanding monkeys' do
    describe '+ positive' do
      let(:app_id) { 'com.test.Example' }
      let(:commander) do
        commander = MonkeyMaster::MonkeyCommander.new(app_id)
        commander.instance_variable_set(:@device_list, device_stubs)
        commander
      end

      describe 'regular run' do
        before do
          allow(commander).to receive(:archive_and_clean_log) { nil }
        end
        it 'should start and stop adb monkeys' do
          device_stubs.each do |device_stub|
            expect(MonkeyMaster::ADB).to receive(:monkey_run).with(app_id, device_stub)
            expect(MonkeyMaster::ADB).to receive(:monkey_stop).with(app_id, device_stub)
          end
          commander.command_monkeys
        end

        it 'should make a log for each iteration of each device' do
          commander.instance_variable_set(:@iterations, 2)
          # two devices, two iterations => 4 runs
          expect(commander).to receive(:archive_and_clean_log).exactly(4).times
          expect(MonkeyMaster::ADB).to receive(:end_logging).once
          commander.command_monkeys
        end

        it 'should kill the monkeys after running' do
          expect(MonkeyMaster::ADB).to receive(:kill_monkeys).with(device_stubs)
          commander.command_monkeys
        end
      end
    end

    describe '- negative' do
      describe 'with an invalid app id' do
        before do
          allow_any_instance_of(MonkeyMaster::MonkeyCommander).to receive(:archive_and_clean_log) { true }
          allow_any_instance_of(MonkeyMaster::MonkeyCommander).to receive(:log_for_device) { true }
        end
        it 'should raise an error' do
          commander = MonkeyMaster::MonkeyCommander.new(nil)
          commander.device_list = device_stubs
          expect { commander.command_monkeys }.to raise_error(ArgumentError)
        end
      end

      describe 'with invalid devices' do
        before do
          allow_any_instance_of(MonkeyMaster::MonkeyCommander).to receive(:archive_and_clean_log) { true }
          allow_any_instance_of(MonkeyMaster::MonkeyCommander).to receive(:log_for_device) {
            raise ArgumentError, 'It doesn’t seem like there are ready, connected devices.'
          }
        end
        it 'should raise an error' do
          commander = MonkeyMaster::MonkeyCommander.new('com.test.Example')
          commander.device_list = device_stubs
          # invalid devices, should raise an exception
          expect { commander.command_monkeys }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
