<!-- DRAFT submission checklist, Sprint 19 (plan/05-sprints.md). Everything here is
     preparation: the actual account setup, key generation, and upload are real,
     externally-visible, hard-to-reverse actions and are deliberately left for the
     app owner to do, not automated. -->

# Store submission prep

## App identity

- Package / bundle id: `id.wudget.wudget` (Android `applicationId`, matches
  `android/app/build.gradle`; iOS bundle id needs to be confirmed in Xcode, see below)
- Version: `1.0.0+1` (`pubspec.yaml`), semantic version + Android version code
- App name: **wudget** (see the name-collision note below, this was a deliberate
  call, not an oversight)

**Name collision, flagged and decided.** A search during this sprint found an
existing iOS app titled "Wudget: Simpler Budget Planner", exact name, same
category (App Store: https://apps.apple.com/us/app/wudget-simpler-budget-planner/id6720702936).
Google Play has no exact "Wudget" listing. The owner's decision was to keep the
name and proceed anyway. Risk to watch for at actual submission: Apple's review
can reject for name confusion even without a trademark claim; if that happens,
the fallback is an App Store-only display name variant (e.g. "wudget - catat &
anggaran") while keeping the Play listing and in-app branding as "wudget".

## Android (Google Play)

1. **Generate the real upload keystore** (not done here, see
   `android/app/build.gradle`'s comment above `signingConfigs` for the exact
   `keytool` command). Store the `.jks` file and its passwords outside this repo.
2. Write `android/key.properties` (gitignored, see `android/.gitignore`) with
   `storePassword`, `keyPassword`, `keyAlias=upload`, `storeFile=<path>`.
3. Build the release bundle: `flutter build appbundle --release`.
4. Create the Play Console app listing, category **Finance**, using
   `store/listing.id.md` (primary locale: Indonesian) and `store/listing.en.md`
   (add English as a second listing locale).
5. Upload the app icon: **not yet designed** (`DESIGN.md`, `[CONFIRM] Logo`).
   The app currently ships Flutter's default launcher icon; replace
   `android/app/src/main/res/mipmap-*/ic_launcher.png` before the store listing
   goes live, a wordmark-only icon is not a finished store icon.
6. Fill in the Data Safety form: no data collected, no data shared, matching
   `legal/privacy-policy.en.md`.
7. Link the published privacy policy URL (publish `legal/privacy-policy.*.md`
   to a real hosted page first, see that file's top comment).
8. Content rating questionnaire: no violence, no user-generated content, no
   gambling, no unrestricted web access, should land in the lowest tier.
9. Screenshots: **in `store/screenshots/`**, five 1170x2532 PNGs (Pantau,
   capture sheet, Catat, Kantong, Anggaran). Both stores accept these sizes.
   They are rendered by `app/test/design_review.dart`, which builds the real
   widget tree with the bundled typeface and a month of seeded Indonesian
   history, so every figure on them is one the app computed. Regenerate with
   `flutter test --update-goldens test/design_review.dart` after a UI change.
   Deliberately not captured from the physical device: that device now holds
   10,000 synthetic rows from the performance gate, which is exactly the
   "synthetic-looking state" plan/05-sprints.md says not to ship.

## iOS (App Store)

Cannot be driven from this Windows environment: an Apple Developer account,
Xcode, and a Mac (or a Mac-in-the-cloud CI runner) are required for signing,
archiving, and TestFlight/App Store upload. What's prepared here:

- `store/app-store-connect.md` has the subtitle, promotional text, keywords,
  and category fields ready to paste into App Store Connect.
- `legal/privacy-policy.*.md` and `legal/terms.*.md` are ready to publish and
  link, same as Android.
- Confirm the iOS bundle identifier in `ios/Runner.xcodeproj` matches
  `id.wudget.wudget` (or register whatever id is actually used) before creating
  the App Store Connect record.
- App icon: same gap as Android, `ios/Runner/Assets.xcassets/AppIcon.appiconset`
  still holds Flutter's placeholder set.

## Not done in this sprint, and why

- **A store video/feature graphic**: neither store requires one to submit.
- **iOS build/archive/signing**: needs Xcode on a Mac; nothing to automate here
  from this environment.
- **Actual store account setup, key generation, and submission**: these are
  real-world, hard-to-reverse, externally-visible actions (a lost upload key is
  not recoverable the same way twice; a live submission puts the app in front
  of Apple/Google review and, if accepted, the public). Left for the owner to
  do deliberately, not run unattended.
