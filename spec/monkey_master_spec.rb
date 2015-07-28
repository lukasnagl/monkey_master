require 'spec_helper'

describe MonkeyMaster::MonkeyCommander do
  let(:device_stubs) { %w(80123 34555) }

  before do
    allow(MonkeyMaster::ADB).to receive(:monkey_run) { 0 }
    allow(MonkeyMaster::ADB).to receive(:monkey_stop) { `echo "testing"` }
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
