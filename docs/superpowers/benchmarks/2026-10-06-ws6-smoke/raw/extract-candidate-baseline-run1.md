# extract-candidate — baseline — run1

Date: 2026-10-05T20:10:01Z
Condition: baseline
Claude: 2.1.289 (Claude Code)
Model: unrecorded
Workdir: /private/var/folders/q0/wtm1jl496mj8hc4r2mrbpfpr0000gn/T/tuist-bench.TFBWWx/extract-candidate
Plugin repo: none (baseline)
Plugin revision: n/a

```text
--- git diff --stat HEAD ---
 App/Tests/AppTests.swift                        |  6 ------
 {App => NetworkingKit}/Sources/Networking.swift |  0
 Project.swift                                   | 20 ++++++++++++++++++++
 3 files changed, 20 insertions(+), 6 deletions(-)
--- changed-file count (including untracked) ---
       7
--- dependency edges (before / after) ---
4a5,8
> Project.swift:26:        .target(
> Project.swift:34:            dependencies: []
> Project.swift:36:        .target(
> Project.swift:44:            dependencies: [.target(name: "NetworkingKit")]
--- mise exec -- tuist install ---
Resolving and fetching plugins.
✔ Success 
  Plugins resolved and fetched successfully. 
--- mise exec -- tuist generate --no-open ---
Loading and constructing the graph
It might take a while if the cache is empty
Using cache binaries for the following targets: 
Generating workspace App.xcworkspace
Generating project App
Total time taken: 0.263s
✔ Success 
  Project generated. 
--- xcodebuild build (scheme App) ---

CodeSign /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Products/Debug-iphonesimulator/App.app (in target 'App' from project 'App')
    cd /var/folders/q0/wtm1jl496mj8hc4r2mrbpfpr0000gn/T/tuist-bench.TFBWWx/extract-candidate
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Products/Debug-iphonesimulator/App.app

Validate /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Products/Debug-iphonesimulator/App.app (in target 'App' from project 'App')
    cd /var/folders/q0/wtm1jl496mj8hc4r2mrbpfpr0000gn/T/tuist-bench.TFBWWx/extract-candidate
    builtin-validationUtility /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Products/Debug-iphonesimulator/App.app -shallow-bundle -infoplist-subpath Info.plist

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/SDKExplicitPrecompiledModules

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Intermediates.noindex/ExplicitPrecompiledModules

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules

** BUILD SUCCEEDED **

--- xcodebuild test (scheme App) ---
2026-10-06 05:10:16.409 xcodebuild[12063:3048393] [MT] IDETestOperationsObserverDebug: 10.726 elapsed -- Testing started completed.
2026-10-06 05:10:16.409 xcodebuild[12063:3048393] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-10-06 05:10:16.409 xcodebuild[12063:3048393] [MT] IDETestOperationsObserverDebug: 10.726 sec, +10.726 sec -- end
    builtin-validationUtility /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Products/Debug-iphonesimulator/App.app -shallow-bundle -infoplist-subpath Info.plist

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Intermediates.noindex/ExplicitPrecompiledModules

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/SDKExplicitPrecompiledModules

2026-10-06 05:10:15.896969+0900 App[12614:3051379] [General] Failed to send CA Event for app launch measurements for ca_event_type: 0 event_name: com.apple.app_launch_measurement.FirstFramePresentationMetric
2026-10-06 05:10:16.002280+0900 App[12614:3051381] [General] Failed to send CA Event for app launch measurements for ca_event_type: 1 event_name: com.apple.app_launch_measurement.ExtendedLaunchMetrics
Test Suite 'All tests' started at 2026-10-06 05:10:16.122.
Test Suite 'All tests' passed at 2026-10-06 05:10:16.122.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds

Test session results, code coverage, and logs:
	/Users/dave/Library/Developer/Xcode/DerivedData/App-ddmlrwyrqkysmjbuwubnxogqwqzo/Logs/Test/Test-App-2026.10.06_05-10-04-+0900.xcresult

** TEST SUCCEEDED **

Testing started
```

Resolve: pass
Generate: pass
Build: pass
Test: pass
