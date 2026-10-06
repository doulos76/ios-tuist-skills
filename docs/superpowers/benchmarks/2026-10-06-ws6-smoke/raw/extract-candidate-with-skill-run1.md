# extract-candidate — with-skill — run1

Date: 2026-10-05T20:18:59Z
Condition: with-skill
Claude: 2.1.289 (Claude Code)
Model: unrecorded
Workdir: /private/var/folders/q0/wtm1jl496mj8hc4r2mrbpfpr0000gn/T/tuist-bench.2nIl8r/extract-candidate
Plugin repo: /Users/dave/Documents/GitHub/ios-tuist-skills
Plugin revision: f40348a9eb8520b3f6faa3fa934fbacf0cc86c91

```text
--- git diff --stat HEAD ---
 {App => NetworkingKit}/Sources/Networking.swift      |  0
 .../Tests/NetworkingKitTests.swift                   |  2 +-
 Project.swift                                        | 20 ++++++++++++++++++++
 3 files changed, 21 insertions(+), 1 deletion(-)
--- changed-file count (including untracked) ---
       6
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
Total time taken: 0.255s
✔ Success 
  Project generated. 
--- xcodebuild build (scheme App) ---

CodeSign /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app (in target 'App' from project 'App')
    cd /var/folders/q0/wtm1jl496mj8hc4r2mrbpfpr0000gn/T/tuist-bench.2nIl8r/extract-candidate
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app

Validate /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app (in target 'App' from project 'App')
    cd /var/folders/q0/wtm1jl496mj8hc4r2mrbpfpr0000gn/T/tuist-bench.2nIl8r/extract-candidate
    builtin-validationUtility /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app -shallow-bundle -infoplist-subpath Info.plist

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Intermediates.noindex/ExplicitPrecompiledModules

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/SDKExplicitPrecompiledModules

** BUILD SUCCEEDED **

--- xcodebuild test (scheme App) ---
2026-10-06 05:19:24.584 xcodebuild[30951:3087674]  iOSSimulator: 1EABBD69-0A25-489C-80A9-0BCDA23A5F5E: Failed to launch app with identifier: dev.ios-tuist-skills.extract-candidate and options: {
    "activate_suspended" = 0;
    arguments =     (
    );
    environment =     {
        "APP_DISTRIBUTOR_ID_OVERRIDE" = "com.apple.AppStore";
        "CA_ASSERT_MAIN_THREAD_TRANSACTIONS" = 0;
        "CA_DEBUG_TRANSACTIONS" = 0;
        "DYLD_FRAMEWORK_PATH" = "/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks:/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks";
        "DYLD_INSERT_LIBRARIES" = "/usr/lib/libRPAC.dylib:/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app/Frameworks/libXCTestBundleInject.dylib:/Library/Developer/CoreSimulator/Volumes/iOS_23F77/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.5.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libMainThreadChecker.dylib:/usr/lib/libRPAC.dylib:/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app/Frameworks/libXCTestBundleInject.dylib:/Library/Developer/CoreSimulator/Volumes/iOS_23F77/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.5.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libMainThreadChecker.dylib:/usr/lib/libRPAC.dylib";
        "DYLD_LIBRARY_PATH" = "/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib:/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib";
        "IDE_CHOSEN_LOGGING_METHOD" = 1;
        "LLVM_PROFILE_FILE" = "/dev/null";
        NSUnbufferedIO = YES;
        "OS_ACTIVITY_DT_MODE" = YES;
        "PERFC_ENABLE_EXTENDED_DIAGNOSTIC_FORMAT" = 1;
        "PERFC_ENABLE_PROFILE_MODE" = 1;
        "PERFC_RESET_INSERT_LIBRARIES" = 1;
        "PERFC_SUPPRESS_SYSTEM_REPORTS" = 1;
        "RUN_DESTINATION_DEVICE_NAME" = "iPhone 17 Pro";
        "RUN_DESTINATION_DEVICE_PLATFORM_IDENTIFIER" = "com.apple.platform.iphonesimulator";
        "RUN_DESTINATION_DEVICE_UDID" = "1EABBD69-0A25-489C-80A9-0BCDA23A5F5E";
        "SQLITE_ENABLE_THREAD_ASSERTIONS" = 1;
        "SWIFT_BACKTRACE" = "enable=no";
        TERM = dumb;
        XCInjectBundleInto = unused;
        "XCODE_SCHEME_NAME" = App;
        XCTestBundleInjectPath = "/usr/lib/libRPAC.dylib:/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app/Frameworks/libXCTestBundleInject.dylib:/Library/Developer/CoreSimulator/Volumes/iOS_23F77/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.5.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libMainThreadChecker.dylib:/usr/lib/libRPAC.dylib:/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app/Frameworks/libXCTestBundleInject.dylib:/Library/Developer/CoreSimulator/Volumes/iOS_23F77/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.5.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libMainThreadChecker.dylib:/usr/lib/libRPAC.dylib";
        XCTestBundlePath = "PlugIns/AppTests.xctest";
        XCTestConfigurationFilePath = "";
        XCTestSessionIdentifier = "8AE0CCA8-C172-483A-B252-53FBC60A60B5";
        "__XCODE_BUILT_PRODUCTS_DIR_PATHS" = "/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator";
        "__XPC_DYLD_FRAMEWORK_PATH" = "/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator:/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator";
        "__XPC_DYLD_LIBRARY_PATH" = "/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator:/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator";
        "__XPC_LLVM_PROFILE_FILE" = "/dev/null";
    };
    stderr = "/dev/ttys000";
    stdout = "/dev/ttys000";
    "terminate_running_process" = 1;
    "wait_for_debugger" = 1;
} (error = Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "Simulator device failed to launch dev.ios-tuist-skills.extract-candidate." UserInfo={NSLocalizedDescription=Simulator device failed to launch dev.ios-tuist-skills.extract-candidate., NSUnderlyingError=0xc66f0a970 {Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "dev.ios-tuist-skills.extract-candidate" failed." UserInfo={BSErrorCodeDescription=RequestDenied, NSLocalizedDescription=The request to open "dev.ios-tuist-skills.extract-candidate" failed., NSUnderlyingError=0xc66f0a5e0 {Error Domain=FBSOpenApplicationErrorDomain Code=6 "Application failed preflight checks" UserInfo={BSErrorCodeDescription=Busy, NSLocalizedFailureReason=Application failed preflight checks}}, FBSOpenApplicationRequestID=0xb854, NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace) for reason: Busy ("Application failed preflight checks").}}, NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace) for reason: Busy ("Application failed preflight checks")., FBSOpenApplicationRequestID=0xb854, SimCallingSelector=launchApplicationWithID:options:pid:error:, BSErrorCodeDescription=RequestDenied})
2026-10-06 05:19:24.585 xcodebuild[30951:3087640] [MT] IDELaunchReport: 5fedb58d0ba74380:5fedb58d0beccd40:Launching AppTests Finished with error: Simulator device failed to launch dev.ios-tuist-skills.extract-candidate.
Domain: FBSOpenApplicationServiceErrorDomain
Code: 1
Failure Reason: The request was denied by service delegate (SBMainWorkspace) for reason: Busy ("Application failed preflight checks").
User Info: {
    BSErrorCodeDescription = RequestDenied;
    DVTErrorCreationDateKey = "2026-10-05 20:19:24 +0000";
    FBSOpenApplicationRequestID = 0xb854;
    IDERunOperationFailingWorker = IDELaunchiPhoneSimulatorLauncher;
    SimCallingSelector = "launchApplicationWithID:options:pid:error:";
}
--
The request to open "dev.ios-tuist-skills.extract-candidate" failed.
Domain: FBSOpenApplicationServiceErrorDomain
Code: 1
Failure Reason: The request was denied by service delegate (SBMainWorkspace) for reason: Busy ("Application failed preflight checks").
User Info: {
    BSErrorCodeDescription = RequestDenied;
    FBSOpenApplicationRequestID = 0xb854;
}
--
The operation couldn’t be completed. Application failed preflight checks
Domain: FBSOpenApplicationErrorDomain
Code: 6
Failure Reason: Application failed preflight checks
User Info: {
    BSErrorCodeDescription = Busy;
}
--

2026-10-06 05:19:24.586 xcodebuild[30951:3087640] [MT] IDELaunchReport: 5fedb58d0ba74380:5fedb58d0beccd40:Launching AppTests com.apple.dt.IDERunOperationWorkerFinished {
    "device_identifier" = "1EABBD69-0A25-489C-80A9-0BCDA23A5F5E";
    "device_model" = "iPhone18,1";
    "device_osBuild" = "26.5 (23F77)";
    "device_osBuild_monotonic" = 23005077000000000;
    "device_os_variant" = 1;
    "device_platform" = "com.apple.platform.iphonesimulator";
    "device_platform_family" = 2;
    "device_reality" = 2;
    "device_thinningType" = "iPhone18,1";
    "device_transport" = 4;
    "launchSession_initiator" = 1;
    "launchSession_schemeCommand" = Test;
    "launchSession_schemeCommand_enum" = 2;
    "launchSession_targetArch" = arm64;
    "launchSession_targetArch_enum" = 6;
    "operation_duration_ms" = 18559;
    "operation_errorCode" = 1;
    "operation_errorDomain" = FBSOpenApplicationServiceErrorDomain;
    "operation_errorWorker" = IDELaunchiPhoneSimulatorLauncher;
    "operation_error_reportable" = 1;
    "operation_name" = IDELaunchiPhoneSimulatorLauncher;
    "param_consoleMode" = 0;
    "param_debugger_attachToExtensions" = 0;
    "param_debugger_attachToXPC" = 0;
    "param_debugger_type" = 1;
    "param_destination_isProxy" = 0;
    "param_destination_platform" = "com.apple.platform.iphonesimulator";
    "param_diag_MTE_enable" = 0;
    "param_diag_MainThreadChecker_stopOnIssue" = 0;
    "param_diag_MallocStackLogging_enableDuringAttach" = 0;
    "param_diag_MallocStackLogging_enableForXPC" = 0;
    "param_diag_allowLocationSimulation" = 1;
    "param_diag_checker_mtc_enable" = 0;
    "param_diag_checker_tpc_enable" = 1;
    "param_diag_gpu_frameCapture_enable" = 3;
    "param_diag_gpu_shaderValidation_enable" = 0;
    "param_diag_gpu_validation_enable" = 1;
    "param_diag_guardMalloc_enable" = 0;
    "param_diag_memoryGraphOnResourceException" = 0;
    "param_diag_queueDebugging_enable" = 0;
    "param_diag_runtimeProfile_generate" = 0;
    "param_diag_sanitizer_asan_enable" = 0;
    "param_diag_sanitizer_mtasan_enable" = 0;
    "param_diag_sanitizer_tsan_enable" = 0;
    "param_diag_sanitizer_tsan_stopOnIssue" = 0;
    "param_diag_sanitizer_ubsan_enable" = 0;
    "param_diag_sanitizer_ubsan_stopOnIssue" = 0;
    "param_diag_showNonLocalizedStrings" = 0;
    "param_diag_viewDebugging_enabled" = 0;
    "param_diag_viewDebugging_insertDylibOnLaunch" = 0;
    "param_install_style" = 2;
    "param_launcher_UID" = 2;
    "param_launcher_allowDeviceSensorReplayData" = 0;
    "param_launcher_kind" = 0;
    "param_launcher_style" = 0;
    "param_launcher_substyle" = 0;
    "param_runnable_appExtensionHostRunMode" = 0;
    "param_runnable_productType" = "com.apple.product-type.application";
    "param_testing_launchedForTesting" = 1;
    "param_testing_suppressSimulatorApp" = 1;
    "param_testing_usingCLI" = 0;
    "sdk_canonicalName" = "iphonesimulator27.0";
    "sdk_osVersion" = "27.0";
    "sdk_platformID" = 7;
    "sdk_variant" = iphonesimulator;
    "sdk_version_monotonic" = 24000430000000000;
}
2026-10-06 05:19:24.586 xcodebuild[30951:3087640] [MT] IDELaunchReport: 5fedb58d0ba74380:5fedb58d0ba74380: Finished with error: Simulator device failed to launch dev.ios-tuist-skills.extract-candidate.
Domain: FBSOpenApplicationServiceErrorDomain
Code: 1
Failure Reason: The request was denied by service delegate (SBMainWorkspace) for reason: Busy ("Application failed preflight checks").
User Info: {
    BSErrorCodeDescription = RequestDenied;
    DVTErrorCreationDateKey = "2026-10-05 20:19:24 +0000";
    FBSOpenApplicationRequestID = 0xb854;
    IDERunOperationFailingWorker = IDELaunchiPhoneSimulatorLauncher;
    SimCallingSelector = "launchApplicationWithID:options:pid:error:";
}
--
The request to open "dev.ios-tuist-skills.extract-candidate" failed.
Domain: FBSOpenApplicationServiceErrorDomain
Code: 1
Failure Reason: The request was denied by service delegate (SBMainWorkspace) for reason: Busy ("Application failed preflight checks").
User Info: {
    BSErrorCodeDescription = RequestDenied;
    FBSOpenApplicationRequestID = 0xb854;
}
--
The operation couldn’t be completed. Application failed preflight checks
Domain: FBSOpenApplicationErrorDomain
Code: 6
Failure Reason: Application failed preflight checks
User Info: {
    BSErrorCodeDescription = Busy;
}
--

2026-10-06 05:19:24.586 xcodebuild[30951:3087640] [MT] IDELaunchReport: 5fedb58d0ba74380:5fedb58d0ba74380: com.apple.dt.IDERunOperationWorkerFinished {
    "device_identifier" = "1EABBD69-0A25-489C-80A9-0BCDA23A5F5E";
    "device_model" = "iPhone18,1";
    "device_osBuild" = "26.5 (23F77)";
    "device_osBuild_monotonic" = 23005077000000000;
    "device_os_variant" = 1;
    "device_platform" = "com.apple.platform.iphonesimulator";
    "device_platform_family" = 2;
    "device_reality" = 2;
    "device_thinningType" = "iPhone18,1";
    "device_transport" = 4;
    "launchSession_initiator" = 1;
    "launchSession_schemeCommand" = Test;
    "launchSession_schemeCommand_enum" = 2;
    "launchSession_targetArch" = arm64;
    "launchSession_targetArch_enum" = 6;
    "operation_duration_ms" = 18561;
    "operation_errorCode" = 1;
    "operation_errorDomain" = FBSOpenApplicationServiceErrorDomain;
    "operation_errorWorker" = IDELaunchiPhoneSimulatorLauncher;
    "operation_error_reportable" = 1;
    "operation_name" = IDERunOperationWorkerGroup;
    "param_consoleMode" = 0;
    "param_debugger_attachToExtensions" = 0;
    "param_debugger_attachToXPC" = 0;
    "param_debugger_type" = 1;
    "param_destination_isProxy" = 0;
    "param_destination_platform" = "com.apple.platform.iphonesimulator";
    "param_diag_MTE_enable" = 0;
    "param_diag_MainThreadChecker_stopOnIssue" = 0;
    "param_diag_MallocStackLogging_enableDuringAttach" = 0;
    "param_diag_MallocStackLogging_enableForXPC" = 0;
    "param_diag_allowLocationSimulation" = 1;
    "param_diag_checker_mtc_enable" = 0;
    "param_diag_checker_tpc_enable" = 1;
    "param_diag_gpu_frameCapture_enable" = 3;
    "param_diag_gpu_shaderValidation_enable" = 0;
    "param_diag_gpu_validation_enable" = 1;
    "param_diag_guardMalloc_enable" = 0;
    "param_diag_memoryGraphOnResourceException" = 0;
    "param_diag_queueDebugging_enable" = 0;
    "param_diag_runtimeProfile_generate" = 0;
    "param_diag_sanitizer_asan_enable" = 0;
    "param_diag_sanitizer_mtasan_enable" = 0;
    "param_diag_sanitizer_tsan_enable" = 0;
    "param_diag_sanitizer_tsan_stopOnIssue" = 0;
    "param_diag_sanitizer_ubsan_enable" = 0;
    "param_diag_sanitizer_ubsan_stopOnIssue" = 0;
    "param_diag_showNonLocalizedStrings" = 0;
    "param_diag_viewDebugging_enabled" = 0;
    "param_diag_viewDebugging_insertDylibOnLaunch" = 0;
    "param_install_style" = 2;
    "param_launcher_UID" = 2;
    "param_launcher_allowDeviceSensorReplayData" = 0;
    "param_launcher_kind" = 0;
    "param_launcher_style" = 0;
    "param_launcher_substyle" = 0;
    "param_runnable_appExtensionHostRunMode" = 0;
    "param_runnable_productType" = "com.apple.product-type.application";
    "param_testing_launchedForTesting" = 1;
    "param_testing_suppressSimulatorApp" = 1;
    "param_testing_usingCLI" = 0;
    "sdk_canonicalName" = "iphonesimulator27.0";
    "sdk_osVersion" = "27.0";
    "sdk_platformID" = 7;
    "sdk_variant" = iphonesimulator;
    "sdk_version_monotonic" = 24000430000000000;
}
2026-10-06 05:19:36.452 xcodebuild[30951:3087640] [MT] IDETestOperationsObserverDebug: 31.624 elapsed -- Testing started completed.
2026-10-06 05:19:36.452 xcodebuild[30951:3087640] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-10-06 05:19:36.452 xcodebuild[30951:3087640] [MT] IDETestOperationsObserverDebug: 31.624 sec, +31.624 sec -- end
Testing failed:
	Simulator device failed to launch dev.ios-tuist-skills.extract-candidate.
	App encountered an error (Failed to install or launch the test runner. (Underlying Error: Simulator device failed to launch dev.ios-tuist-skills.extract-candidate. The request was denied by service delegate (SBMainWorkspace) for reason: Busy ("Application failed preflight checks"). (Underlying Error: The request to open "dev.ios-tuist-skills.extract-candidate" failed. The request was denied by service delegate (SBMainWorkspace) for reason: Busy ("Application failed preflight checks"). (Underlying Error: The operation couldn’t be completed. Application failed preflight checks))))

** TEST FAILED **


Validate /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app (in target 'App' from project 'App')
    cd /var/folders/q0/wtm1jl496mj8hc4r2mrbpfpr0000gn/T/tuist-bench.2nIl8r/extract-candidate
    builtin-validationUtility /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Products/Debug-iphonesimulator/App.app -shallow-bundle -infoplist-subpath Info.plist

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/SDKExplicitPrecompiledModules

PruneExplicitPrecompiledModules /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Build/Intermediates.noindex/ExplicitPrecompiledModules



*** If you believe this error represents a bug, please attach the result bundle at /Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Logs/Test/Test-App-2026.10.06_05-19-04-+0900.xcresult


Test session results, code coverage, and logs:
	/Users/dave/Library/Developer/Xcode/DerivedData/App-fendkfgsuhadkzgiyhlwaececzsw/Logs/Test/Test-App-2026.10.06_05-19-04-+0900.xcresult

Testing started
```

Resolve: pass
Generate: pass
Build: pass
Test: fail
