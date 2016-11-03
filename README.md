Spotify iOS Metadata framework
=======

This framework has been previously a part of the Spotify iOS SDK. It is a wrapper for [Spotify Web API](https://developer.spotify.com/web-api/), designed and implemented to facilitate the usage of Web API. Spotify iOS Metadata Framework is implemented in Objective-C and allows making Web API requests and storing the received data conveniently in a manner that is comfortable for a developer of iOS mobile applications.

#### Bugs or feature requests
[Open bug tickets](https://ghe.spotify.net/apps-sdk/ios-metadata/labels/bug) | [Open feature requests](https://ghe.spotify.net/apps-sdk/ios-metadata/labels/enhancement) | [All](https://ghe.spotify.net/apps-sdk/ios-metadata/issues)

Beta Release Information
=======

For known issues and release notes, see the
[CHANGELOG.md](https://ghe.spotify.net/apps-sdk/ios-metadata/blob/master/CHANGELOG.md)
file.

Requirements
=======

The Spotify iOS SDK requires iOS a deployment target of iOS 7 or higher. The
following architectures are supported: `armv7`, `armv7s` and `arm64` for devices,
and `i386` and `x86_64` for the iOS Simulator. The `i386` and `x86_64` slices
*cannot* be used to build Mac applications.


Getting Started
=======

[Spotify Developer Portal](https://developer.spotify.com/technologies/spotify-ios-sdk/) | [Web API Reference](https://developer.spotify.com/web-api/)

### Using the Spotify iOS Metadata framework

Getting the Spotify iOS Metadata frameworkinto your application is easy:

1. Add the library `SpotifyMetadata.framework` to your Xcode project.
2. Add the `-ObjC` flag to your project's `Other Linker Flags` build setting.
3. Import the umbrella headers from the framework into your source files. 

After that you are ready to develop your application.

The library's headers are extensively documented, and they come with an Xcode
documentation set which can be indexed by Xcode itself and applications like
Dash. 

*   Metadata classes contain methods for doing corresponding metadata lookup. `SPTUser` is for userinfo, `SPTSearch` for searching.


