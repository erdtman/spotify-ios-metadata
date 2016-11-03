Spotify iOS Metadata Framework Beta 26
=======================


Spotify iOS SDK Beta 25
=======================

**Bugs fixed**

* [`SPTSearch performSearchWithQuery:` offset is broken](https://github.com/spotify/ios-sdk/issues/478)
* [`SPTSearch performSearchWithQuery:` crash](https://github.com/spotify/ios-sdk/issues/766)
* [Beta 24 emits a lot of warnings](https://github.com/spotify/ios-sdk/issues/782)
* [b24 frameworks do not support bitcode while b23 did](https://github.com/spotify/ios-sdk/issues/786)

Spotify iOS SDK Beta 24
=======================

SDK is now split into Authentication, Metadata and AudioPlayback frameworks independent from each other.

**API Changes**

All classes and methods have been moved into appropriate frameworks.

**Bugs fixed**

* Fixed library hanging on 32 bit systems. (#772, #777)
* `SPTPartialPlaylist` now correctly parses name and uri as nil when the object is `NSNull`
* [SPTPlaylistTrack decodedJSONObject is nil](https://github.com/spotify/ios-sdk/issues/396)
* [requestNewReleasesForCountry returns nil items](https://github.com/spotify/ios-sdk/issues/387])

Spotify iOS SDK Beta 23
=======================

**Bugs fixed**

* [Beta 22: `SPTPlaylistSnapshot +playlistsWithURIs...` is gone.](https://github.com/spotify/ios-sdk/issues/761)


Spotify iOS SDK Beta 22
=======================

In preparation for splitting our SDK into distinct components the focus of this release is to decouple future components.
SDK is now grouped into Authentication, Metadata and AudioPlayback functionality modules independent from each other. This functionality grouping is reflected in the "Spotify.h" header. SDK will be split into three libraries representing these functionality modules in an upcoming release.
Decoupling manifested in that all methods concerning Metadata that previously took a SPTSession object now instead take an `NSString *accessToken` argument which is a property of the `SPTSession` object.
E.g. `SPTArtist` method `requestTopTracksForTerritory:withSession:callback:` becomes `requestTopTracksForTerritory:withAccessToken:callback:`. If such a method was already present then the method referencing session was simply removed.

**API Changes**

* Removed all methods marked as deprecated in `SPTArtist` and `SPTRequest`. These methods have been previously moved to other interfaces, but not deleted at their original location.
