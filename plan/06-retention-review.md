# Retention round: design review against the mockup

PNGs in `app/test/design_review/`, rendered by `flutter test --update-goldens test/design_review.dart`.
Compared with [design/Retention.html](../design/Retention.html), screens 1 to 8.

| Screen | PNG | Difference | Decision |
|---|---|---|---|
| 1, 7 Home | catat, catat_dark, catat_empty | "Sering kamu catat jam segini" was uppercase with wide tracking | Fixed: sentence case, same label style as the other home labels |
| 1 Home | catat | Quick chips were full pills | Fixed: chip radius (11), bordered, like the mockup |
| 1 Home | catat | Payday card sits above the date on the 25th to 24th seed | Accepted: the card is the day's one question; the seed lands inside its window |
| 2, 3 Capture | capture, capture_dark | Category label "Kategori, diurutkan..." was uppercase | Fixed: sentence case |
| 4a Payday card | payday_card(_dark) | None worth noting | - |
| 4b Review | payday_review(_dark) | None worth noting | - |
| 4c Set now | set_now(_dark) | Sheet overflowed at 200% text | Fixed: the sheet scrolls when it has to |
| 5 Recap | recap(_dark) | Label and value rows overflowed at 200% text | Fixed: the value wraps under its label |
| 6 Comeback | comeback(_dark) | Mockup puts sentence, dots and "11 dari 17 hari tercatat. Tidak ada yang hilang." in one card; the app reuses the home strip card, so the count sits in the strip header and the line under it reads "Tidak ada yang hilang. Hitungannya tetap." | Accepted: one strip widget everywhere, the count is not printed twice |
| 6 Comeback | comeback | Mockup has no backfill screen | Added: backfill(_dark), one day per screen, "Lewati hari itu" to skip, last 7 missed days at most |
| 8 Pantau | pantau(_dark) | Kantong row numbers overflowed at 200% text; rows read as fragments to a screen reader | Fixed: numbers wrap under the name; each row reads as one sentence |
| Saya | saya, saya_dark | New "Pengingat" group: evening, payday, weekly recap, all on by default | Not in the mockup; follows rule 7 |
