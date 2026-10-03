#!/bin/bash
# Prints the UDID of the first available iPhone simulator. Shared by the CI
# Test step and the early pre-boot step so both pick the same device.
set -euo pipefail
xcrun simctl list devices available --json | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  iphone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "No available iPhone simulator found" unless iphone
  print iphone.fetch("udid")
'
