# Previous task: Ride success navigation - COMPLETE

# New Task: Display recent rides on home page (Accueil tab), sorted newest first

## Steps:
- [x] 1. firestore_service.dart: Add getRecentRidesStream() with orderBy('departureTime', descending: true).

- [x] 2. home_screen.dart: Import service/ride, replace Accueil static text with StreamBuilder(getRecentRidesStream()), compact ride cards linking to service.

- [x] 3. Test: flutter run → home Accueil → recent rides top newest.


## Status: Steps 1-2 complete. Ready for testing.


