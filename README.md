`monkey_master` - A tool for conveniently employing Android adb monkeys.
================================================================

[![Build Status](https://travis-ci.org/j4zz/monkey_master.svg)](https://travis-ci.org/j4zz/monkey_master)

Android's adb offers the ui/application exerciser [monkey](http://developer.android.com/tools/help/monkey.html). Conveniently employing it can be cumbersome, though:

* It's inconvenient to kill a running monkey.
* You can't let it run unobserved for extended periods of time because it ends after a crash or a freeze.
* You either watch the log in your (running) sdk, or you manually handle logcat.
* Managing all of the above on multiple devices is a real pain.

`monkey_master` is a convenience tool for solving these issues. It can easily be combined with other tools, for example to build a fully automated build & test system.

Besides having convenience commands for starting and killing adb monkeys, it has multi-device support (simultaneously running monkeys on multiple devices) and automatically creates log files for each device.

For an example of a `monkey_master` test setup, and the reasoning behind the project, visit [this blog post](http://innovaptor.com/blog/2013/08/18/building-an-automated-testing-and-error-reporting-system-for-android-apps-with-monkey-master-and-crashlytics.html).

Installation
================================================================
`monkey_master` is available as a ruby gem:

	gem install monkey_master

`adb` needs to be in your *PATH* variable. To do this, you could add the following to your `~/.bashrc` or `~/.profile` for example:

	export PATH=/YOUR/PATH/android-sdks/platform-tools:$PATH

Furthermore, you need to have a device in *development mode* connected. Currently, `monkey_master` is not tested with an emulator. For a list of connected devices, use `adb devices`.

Usage
================================================================

	Usage:
  		monkey_master <app_id> [--devices <devices>] [--iterations <iterations>] [-k]
  		monkey_master -k
  		monkey_master -h | --help
  		monkey_master --version

Usage Examples
----------------------------------------------------------------
An example for a test run could be:

	monkey_master com.my.App --iterations 100

If you want to stop the monkeys, either SIGINT (keyboard interrupt) the `monkey_master` during execution, or call:

	monkey_master -k

If you have multiple devices connected, and want to use `monkey_master` on some of them only, call:

	monkey_master com.my.App --devices DEVICEID1,DEVICEID2 --iterations 100

Crash Reporting
================================================================
You might want to use `monkey_master` with a crash reporting tool such as [fabric](https://fabric.io/). Simply integrate the crash reporting library of your choice in your Android App, and `monkey_master`’s crashes will get reported there.

Android Edge Cases
================================================================
Sometimes you encounter errors that only a monkey can generate, but that you can’t reasonably fix in your code. In case of such an error, you will want to exit gracefully if the user is a monkey (in order to suppress useless crash reports), but leave the error handling as it is for production.

Furthermore, you might want to disable certain network calls, or redirect them to a test server.

For such cases, there’s ActivityManager.isUserAMonkey():

```java
if(ActivityManager.isUserAMonkey()) {
    // Work on the test server
} else {
    // Work on the production server
}
```

Contributing
================================================================
Code style or beauty fixes are just as welcome as pull requests, bug reports or ideas.