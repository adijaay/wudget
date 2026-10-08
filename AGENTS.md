<!-- antislop:start -->
## antislop
For UI, copy, people, mobile layout, or code comments work, load the antislop skill for the task:
- Core filter, always on: `antislop`
- UI / visual: `antislop-ui`
- Copy & text: `antislop-copywriting`
- People: `antislop-human`
- Mobile / responsive: `antislop-layoutmobile`
- Code comments: `antislop-code`
Before starting, ask the user when antislop applies: during the work, or after it is done.
<!-- antislop:end -->

## Token hygiene
- Find code with `search_files` first, then read only the line range you need. Do not read whole files over ~200 lines.
- Do not re-read a file after patching it: the patch result already shows the diff. Re-read only if a patch fails.
- Run tests quietly and narrowly: `flutter test --reporter compact <file> 2>&1 | tail -30`. Run only the affected test files while working; run the full suite once at the end of a sprint.
- Never open `*.g.dart` or `pubspec.lock`.
- Load a skill once per session, only when its task applies.
