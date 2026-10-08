# 11. Notification capture policy

Sprint 11 spike (plan/06-audit-fixes.md, ticket 2). Question: can wudget keep reading payment notifications, and does the answer change between a sideloaded APK and a Play Store build?

None of the platform or Play policy claims below were checked against a live source during this spike. They are marked **[unverified]** and must be confirmed against the current Android docs and the Play Developer Policy Center before a Play submission.

## What the app does today

- `PaymentListenerService.kt` is a `NotificationListenerService`, declared in `AndroidManifest.xml` with `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`. The user must enable it by hand in system settings (Notification access); there is no runtime prompt.
- It ignores everything except an allowlist in `PaymentParser.kt`: GoPay (`com.gojek.app`, `com.gojek.gopay`), Livin', Jago (`com.jago.digitalBanking`), ShopeePay (`com.shopee.id`). Debug builds also accept `com.android.shell` so the flow can be tested with `adb shell cmd notification post`.
- A parsed payment is de-duplicated (same amount within 3 minutes) and written to SharedPreferences (`pending_payments`). Flutter reads that queue on the next launch (`main.dart`, `payment_auto_save_repository.dart`). Nothing leaves the phone.
- The class doc comment used to say "Nothing is saved here", which no longer matched `autoSave`; corrected during this spike.

## Sideloaded vs Play-distributed

- **Platform** [unverified]: the notification-listener grant is a special app access the user toggles in settings. On Android 13+, apps installed outside a store via some installers are put under "restricted settings", so the toggle is greyed out until the user allows it from the app's info screen. A sideloaded APK therefore needs a short in-app explanation of that extra step.
- **Play** [unverified]: Play has no permissions declaration form specifically for `BIND_NOTIFICATION_LISTENER_SERVICE` the way it does for SMS and Call Log, but the User Data policy applies: prominent in-app disclosure before sending the user to the setting, a privacy policy that names notification content, and use limited to the stated feature. Reading financial notifications for a budgeting feature is the kind of core-feature use the policy allows, provided the disclosure is explicit.
- **Data safety form** [unverified]: notification content that is processed only on device and never transmitted may not need to be declared as "collected", but the form's definitions should be read before answering.

## Path forward

1. Keep the allowlist approach: it is the strongest argument in a Play review that the access is narrow.
2. Add a disclosure screen before opening Notification access settings (what is read, which apps, that it stays on the phone, how to turn it off).
3. For sideloaded builds, add one line on the restricted-settings step for Android 13+.
4. Before the first Play upload, verify every [unverified] line above and record the outcome in DECISIONS.md.

## Ticket 1 resolution: real bank logos

Not shipped, by decision. wudget has no licence to ship GoPay, OVO, DANA, ShopeePay, BCA or Mandiri artwork; wallets keep a type icon on a neutral ground (`wallets_screen.dart`, DECISIONS.md, R-23). Revisit only with written permission from a provider.
