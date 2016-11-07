Spotify iOS Metadata framework
=======

This framework is a wrapper for [Spotify Web API](https://developer.spotify.com/web-api/). It has been designed and implemented to facilitate the usage of Web API. Spotify iOS Metadata Framework is implemented in Objective-C and allows making Web API requests and storing the received data conveniently in a manner that is comfortable for a developer of iOS mobile applications.

#### Bugs or feature requests
[Open bug tickets](https://ghe.spotify.net/apps-sdk/ios-metadata/labels/bug) | [Open feature requests](https://ghe.spotify.net/apps-sdk/ios-metadata/labels/enhancement) | [All](https://ghe.spotify.net/apps-sdk/ios-metadata/issues)

Release Information
=======

For known issues and release notes, see the
[CHANGELOG.md](https://ghe.spotify.net/apps-sdk/ios-metadata/blob/master/CHANGELOG.md)
file.

Requirements
=======

The Spotify iOS Metadata framework requires a deployment target of iOS 7 or higher. The
following architectures are supported: `armv7`, `armv7s` and `arm64` for devices,
and `i386` and `x86_64` for the iOS Simulator. The `i386` and `x86_64` slices
*cannot* be used to build Mac applications.


Getting Started
=======

[Spotify Developer Portal](https://developer.spotify.com/technologies/spotify-ios-sdk/) | [Web API Reference](https://developer.spotify.com/web-api/)

### Using the Spotify iOS Metadata framework

Getting the Spotify iOS Metadata framework into your application is easy:

1. Add the library `SpotifyMetadata.framework` to your Xcode project.
2. Add the `-ObjC` flag to your project's `Other Linker Flags` build setting.
3. Import the umbrella header `<SpotifyMetadata/SpotifyMetadata.h>` from the framework into your source files. 

After that you are ready to develop your application.

The library headers are extensively documented, and they come with an Xcode
documentation set which can be indexed by Xcode itself and applications like
Dash. 

*   Metadata classes contain methods for doing corresponding metadata lookup. `SPTUser` is for userinfo, `SPTSearch` for searching.

Authenticating and Scopes
=========================

You can generate your application's Client ID, Client Secret and define your
callback URIs at the [My Applications](https://developer.spotify.com/my-applications/)
section of the Spotify Developer Website. To use that functionality, use Spotify iOS Authentication framework, which is currently a part of the [Spotify iOS SDK](https://github.com/spotify/ios-sdk)

When connecting a user to your app, you *must* provide the scopes your
application needs to operate. A scope is a permission to access a certain part
of a user's account, and if you don't ask for the scopes you need you will
receive "permission denied" errors when trying to perform various tasks.

You do *not* need a scope to access non-user specific information, such as to
perform searches, look up metadata, etc. A full list of scopes can be found on
[Scopes](https://developer.spotify.com/web-api/using-scopes/) section of the
Spotify Developer Website.

If your application's scope needs to change after a user is connected to your app,
you will need to throw out your stored credentials and re-authenticate the user 
with the new scopes.

**Important:** Only ask for the scopes your application needs. Requesting playlist
access when your app doesn't use playlists, for example, is bad form.

Contributing
=========================

You are welcome to contribute to this project. Please make sure that:
* New code is covered with tests
* Features and APIs are well documented
* Bitcode support remains enabled 

## Code of conduct
This project adheres to the [Open Code of Conduct][code-of-conduct]. By participating, you are expected to honor this code.

[code-of-conduct]: https://github.com/spotify/code-of-conduct/blob/master/code-of-conduct.md


