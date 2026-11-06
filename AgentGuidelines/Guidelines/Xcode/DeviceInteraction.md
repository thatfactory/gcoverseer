# Device Hub, Physical Devices, and Simulators

Use this guide when verifying an Apple-platform interface or investigating runtime behavior. Follow [Xcode MCP](MCP.md) for tool priority and documentation lookup. A successful build proves compilation; it does not prove that taps, focus, keyboard transitions, presentation, or cancellation work.

## Select the environment

1. Read the consumer's nearest `AGENTS.md` for its designated simulator, account, signing, CI, resource, and accessibility-testing constraints. Reuse that environment; do not create, erase, or boot extra simulators merely for convenience.
2. Use a physical device only when the owner explicitly requests physical-device interaction for the current task. A request for an iPhone-sized interface or visual verification does not imply permission to use a paired personal device. Existing task authorization remains valid; do not ask again for each ordinary test action.
3. Verify that the feature is available on the selected runtime and hardware using current Apple documentation and the framework's availability API. Simulator support varies: a fallback screen or unavailable Apple Intelligence feature does not verify the real native feature. Report that limitation and obtain physical-device authorization if needed.
4. Record the app revision/build, scheme, configuration, Xcode/SDK versions, device model, OS, locale, and relevant input settings. Resolve the exact destination identifier locally; do not publish personal device names, serial numbers, or identifiers in shared documentation.
5. Assign one operator to the interactive session. Concurrent agents must not tap, launch, install, or change settings on the same device. Coordinate builds and simulator use with CI before starting.

Apple describes simulator limitations and run destinations in [Running your app on simulated or physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices). Simulator success is not physical-device performance or feature evidence.

## Discover tools and skills

Inspect the tools actually exposed by the host before choosing a workflow. Prefer native Xcode MCP operations on the open project; external access uses `xcrun mcpbridge` and requires the user's Xcode permission. Use XcodeBuildMCP when native tooling is unavailable or cannot perform the needed operation. It can provide build, install, launch, and logging support without necessarily providing physical-device touch control.

Read the installed `device-interaction` skill when available. It describes workspace-backed versus already-installed-app sessions, install/run, event synthesis, hierarchy capture, and session cleanup. If that installed skill requires a subagent, give it exclusive session ownership. Read an installed iOS debugger skill for XcodeBuildMCP workflows when relevant; a simulator-oriented skill does not establish physical-device support. Skill and tool names vary by installation: discover their current schemas, and do not call an operation merely because a guide mentions it. Distill policy rather than copying exported skill implementations into the repository.

For native device sessions, prefer a workspace-backed session when building the app and an existing-app session when no build is needed. Use one-run arguments and environment variables instead of editing shared schemes. Capture the hierarchy and screenshot, interact, recapture, then end the session. When a hierarchy provides hit points or application-activation annotations, follow the installed tool's contract. A remote placeholder without children requires visual targeting; it does not prove that the device has no controls.

When the required interaction is unavailable through MCP, use the host's supported computer-use capability to operate Device Hub. Do not invent touch support in a build-only tool or replace a missing physical test with simulator evidence.

## Prepare and run a physical device

Use the owner's already paired, unlocked device when possible. Pairing, trust confirmation, Developer Mode, account sign-in, and passcodes are security prerequisites for the owner to complete when required; do not automate around them or reset trust to repair a test. Select the authorized device in Device Hub and verify its model and OS before installing anything. See Apple's [device management](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub) and [Device Hub access](https://support.apple.com/guide/personal-safety/ips37dbab2a1/web) documentation.

Build for the exact destination with the project's normal development signing, provisioning, bundle identifier, and required entitlements. An unsigned CI build is not an interactive device build. Keep install, launch, and UI verification as separate evidence: installation can succeed while launch fails, and launch can succeed while the intended screen is absent. Preserve the existing app container and user data; uninstalling the user's app or resetting its storage is not a routine troubleshooting step.

If MCP cannot perform an operation, Apple's command-line tools are a fallback. Inspect the installed help first, because options and device support change. These examples use placeholders, not literal device identifiers:

```sh
xcodebuild -version
xcrun devicectl list devices
xcrun devicectl help device install app
xcrun devicectl help device process launch

xcrun devicectl device install app --device '<device-id>' '<signed-app-path>'
xcrun devicectl device process launch --device '<device-id>' '<bundle-id>'
```

Select the correct signed build before installation; discovering a device is not authorization to use it. Keep command output containing identifiers local. For console capture, the installed `devicectl device process launch --console` can attach the app's standard streams and wait for exit. Use the supported per-launch environment options for diagnostic configuration. A console stream is not automatically a complete unified-log archive; verify that the required events actually arrive. Stopping that console can forward signals to the app, so coordinate termination and restore an ordinary launch afterward.

## Operate Device Hub

Open **Xcode → Open Developer Tool → Device Hub**, select the target, and choose **View Screen** for a physical device. The Xcode 27 Device Hub app identifier is `com.apple.dt.Devices`; confirm the app/window in the host's current inventory rather than relying on a fixed filesystem path. Apple's [interaction guide](https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-device-hub) describes the canvas, bezel, and platform-specific controls.

Use the following observation loop:

1. Select the intended device window and read its accessibility tree. If multiple windows exist, identify the right one by its title and visible device before acting.
2. Capture a fresh screenshot. The Mac accessibility tree may expose only Device Hub's toolbar and menus, not the mirrored app's controls. Prefer semantic controls where available; otherwise derive targets from the current screenshot.
3. Use the coordinate system documented by the active computer-use tool. A Device Hub window screenshot includes its toolbar and bezel; it is not the same coordinate space as a raw device screenshot or UIKit points. Do not assume Retina scaling or divide coordinates by two. Re-observe after resizing, changing windows, or rotating.
4. Perform the smallest action, then refresh the hierarchy and screenshot before choosing the next target. A tool reporting success proves input delivery, not the expected UI transition.
5. If an action has no effect, recapture and retry once with fresh evidence. Check focus, animation, overlays, and device connection before attempting a different path. Stop guessing when the target remains inaccessible.

Use the tools' state capture and animation handling for synchronization. Do not add arbitrary waits as the default way to make interactions succeed.

In observed Xcode 27 automation, the expanded hub could return `noWindowsAvailable` even though Device Hub was open. Selecting the target's compact device window made capture available. Treat this as a bounded workaround to verify against the current UI, not a guaranteed API behavior. Do not repeatedly relaunch the app or reset the phone to repair a window-capture problem.

Accessory cards, notifications, and permission sheets can intercept input. Exclude a trial if the intended app action never occurred. Dismiss only a visible, understood obstruction within task scope, then re-establish the starting state; do not change unrelated notification or accessory settings.

### Keyboard and tvOS controls

Before testing a software-keyboard issue, inspect **Device → Keyboard** and record the current **Simulate Hardware Keyboard** and keyboard-capture settings when present. Hardware-keyboard simulation can suppress the onscreen keyboard and invalidate a comparison. With authorization for the diagnostic configuration, disable simulation as needed and use an ordinary disposable text field as a positive control: verify that the software keyboard visibly appears. **Toggle Software Keyboard** alone is not proof that normal focus will present it. Keep the configuration identical across trials and restore the original settings afterward.

Focus the device canvas before sending Mac keyboard input, and check where it lands. For tvOS, move focus with arrow keys, activate with Return, and go back with Escape; use the current Device Hub controls or simulated remote for actions such as Home and Play/Pause. tvOS uses focus navigation, not touchscreen coordinate taps. Product-specific navigation and fixture instructions remain in the consumer repository.

### tvOS current-user data and CloudKit

Apple's [current-user guidance](https://developer.apple.com/documentation/tvservices/personalizing-your-app-for-each-user-on-apple-tv) and [multi-user sample](https://developer.apple.com/documentation/tvservices/mapping-apple-tv-users-to-app-profiles) say that the User Management capability gives each selected tvOS user separate preferences and iCloud data. For tvOS 16 and later, the sample uses `runs-as-current-user-with-user-independent-keychain`. That entitlement value does not itself opt data into the shared Keychain; `kSecUseUserIndependentKeychain` is a separate API for apps that deliberately share a service login. A personal-data app should not add manual `TVUserManager` profile mapping to compensate for an unverified system account context.

When testing an app that depends on this separation, use two distinct, fully signed-in Apple TV accounts on an authorized physical device. Confirm the current profile in native Settings, then launch the same signed build through the app grid under each profile. Record the effective app entitlement and embedded provisioning privilege, a fresh process and loaded-build identity, and the account identity returned by the app's CloudKit boundary. Compare that verified account, the bound local store/checkpoint, and a synthetic entry set across A → B → A and cold launches. Retain only privacy-safe equality results; do not publish account or record identifiers or learner content. A changed Settings selection, new process, successful build, `shouldStorePreferencesForCurrentUser == true`, or distinct-looking UI alone does not prove that CloudKit supplied a different account.

If B is selected but CloudKit verifies A, separate that observation from an app bug where CloudKit verifies B but the host opens A's store. A temporary debug-only `UserDefaults` marker written under A and checked without a B write can independently test preference isolation; remove it afterward. Preserve the signed build, process timeline, account/store comparisons, and any existing containers before trying a repair. On one observed tvOS device, both supported current-user entitlement values and a full restart still routed the secondary profile to the default account; removing and re-adding only that secondary profile restored distinct CloudKit accounts and stores across repeated switches. That result does not establish the internal tvOS cause or guarantee the same repair elsewhere.

After one normal restart fails, [removing a secondary Apple Account profile](https://support.apple.com/guide/tv/atvb0753b37d/tvos) is a later owner-coordinated diagnostic: verify the secondary user's local data is replaceable, obtain action-time confirmation, let the owner handle Apple Account sign-in, and leave the default and unrelated profiles untouched. Repeat the same native account/store comparisons after re-addition. Do not uninstall the app, clear checkpoints, change entitlements, or factory-reset the device as a speculative account-routing fix. If separation still fails, preserve a bounded reproduction for Apple support; do not conceal the mismatch with an unverified app-side account mapping.

### Sensor limitations

Apple documents camera and microphone conflicts during physical-device remote interaction. An active Device Hub screen session can prevent sensor access or be interrupted by higher-priority apps. Stop remote interaction and arrange an owner-operated check when real camera or microphone behavior is the test target. Do not label an empty capture caused by the test environment as an application defect, and do not terminate an unrelated call or recording to continue testing.

## Simulator basics

Reuse the consumer-designated simulator by its resolved identifier and check its current boot state. Build for that simulator's platform and architecture, install a normally signed interactive build with the required entitlements, and verify launch before interaction. For entitlement-dependent services such as CloudKit, inspect signing and entitlements before retrying a startup failure. Do not reuse `CODE_SIGNING_ALLOWED=NO` CI output for those UI checks. A project's `CI=true` format-phase bypass is separate from code signing; follow the consumer's build instructions.

On a shared CI host, check active CI before booting or using simulators and obey the consumer's exclusivity rule. Xcode Canvas can create a separate preview simulator even when a different run destination is selected. On constrained hosts, hide Canvas and disable automatic refresh while testing the designated simulator; stop the designated simulator before an intentional preview session, then stop the preview environment before resuming it. Do not shut down a device or session owned by another task or CI.

For CLI fallback, inspect `xcrun simctl help` and the installed subcommand help, and resolve destinations with `xcrun simctl list devices`. Avoid blanket boot, shutdown, erase, or device-creation commands. Keep changes to locale, appearance, accessibility sizes, keyboard settings, and synthetic fixtures scoped to the test and restore them afterward.

## Capture and interpret evidence

Define the expected result before acting. For ordinary navigation, capture the starting state, action, and settled result. For a transient issue, such as a keyboard flashing during presentation, the transient itself is the acceptance target; do not dismiss it merely because the final screen looks correct.

Use [Device Hub screenshots and recording](https://developer.apple.com/documentation/xcode/capturing-screenshots-and-videos-from-devices) when supported by the selected device and tool. Native device screenshots and host-window captures have different framing and resolution. Apple's recording instructions cover simulated devices; do not assume the same recording command supports a physical device. If recording is unavailable, capture a bounded sequence of screenshots around the action with timestamps. Call it a screenshot sequence, not a video, and report sampling gaps that could miss a short event.

Correlate inspected frames with privacy-safe lifecycle, focus, keyboard, cancellation, and completion events under the [logging policy](../Logging.md). Prefer monotonic time and local attempt counters. Record where capture timing begins; an offset measured after a click or hierarchy request differs from an app log measured at presentation request. Notification delivery alone does not prove visible keyboard coverage or identify the first responder. Conversely, a visible flash without an app-owned focus event does not prove which system component caused it.

For a controlled comparison, change one candidate cause at a time, keep the device, build configuration, input state, locale, and synthetic content equivalent, and repeat valid trials. Mark interrupted or confounded trials as excluded. When app-specific presentation is still a candidate, an authorized minimal native host can isolate it: use a separate bundle identifier, the same relevant public API configuration, no real account or app data, and no persistence of generated results. Cancel the workflow and preserve the reproduction locally. Reproduction in that host shows the removed app layers are unnecessary to trigger the symptom; it does not establish an exact internal framework defect or justify an untested production workaround.

Keep screenshots, logs, and reproduction artifacts out of public commits when they contain personal names, notifications, accounts, device identifiers, or authored content. Use synthetic inputs, inspect retained evidence, and sanitize any report before sharing it. Do not log text-field contents or generated images to make timing easier to measure.

## Cleanup and handoff

- Cancel test editors and discard only the synthetic drafts created for the test; confirm the original data remains intact.
- Remove temporary diagnostics and one-run overrides, restore changed keyboard/environment settings, and relaunch the ordinary signed app when the test displaced it. Reuse the existing correct build when possible.
- Stop owned console captures, recordings, device-interaction sessions, and disposable simulator/preview processes. Restore the prior device environment without unpairing devices or changing security settings.
- Remove only a known disposable harness created for this test when its deletion is authorized and it contains no user data. Never uninstall an existing user app as cleanup. Preserve the minimal source and useful sanitized evidence separately when needed for a report.
- Report the exact tested configuration, actions, observed results, excluded trials, diagnostics, evidence locations, limitations, and cleanup status. Separate confirmed observations from hypotheses and unavailable verification. A negative comparison is a useful result; do not ship a speculative fix to make the investigation appear successful.
