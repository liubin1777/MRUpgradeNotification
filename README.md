# MRUpgradeNotification

## What is it?

This is a simple singleton class that will automatically
check the app store every day and alert the user at launch
when there's a new application version available.

## Usage

Adding this class to your project is simple:

1. Import the header file into your application delegate
2. Add this code to your `application:application didFinishLaunching` function:

    	[MRUpgradeNotification checkUpgradeForAppID:123456];

Where `123456` is your application's App Store ID

## Screenshot

![What it looks like](https://github.com/markrickert/MRUpgradeNotification/raw/master/screenshots/example.png)

## Dependencies

This project relies on Stig Brautaset's superb JSON parsing library: [json-framework](https://github.com/stig/json-framework/). You must have this library in your project for this code to work properly.

## Credits

This code was prompted by Marlin Schrock. He saw something similar in another
app and I couldn't find any Open Source code to reproduce it. So I decided to
write it myself.