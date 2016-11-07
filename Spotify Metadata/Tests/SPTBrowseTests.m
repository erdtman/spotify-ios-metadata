/*
 Copyright (c) 2015-2016 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"

#import "SPTRequest_Internal.h"
#import "SPTFeaturedPlaylistList.h"
#import "SPTPartialPlaylist.h"
#import "SPTBrowse.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTBrowseTests : XCTestCase

@end

@implementation SPTBrowseTests

- (void)setUp
{
	[super setUp];
	// Put setup code here; it will be run once, before the first test case.
	[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"api.spotify.com"];
	[SPTRequest setSharedHandler:nil];
}

- (void)tearDown
{
	// Put teardown code here; it will be run once, after the last test case.
	[super tearDown];
	[SPTRequest setSharedHandler:nil];
}

- (void)testParsingFeaturedPlaylistList
{
	NSString *response =@"{ \
	\"message\" : \"Need a morning pick-me-up?\", \
	\"playlists\" : { \
	\"href\" : \"https://api.spotify.com/v1/browse/featured-playlists?country=SE&locale=sv_SE&timestamp=2014-10-23T09:00:00&offset=0&limit=20\", \
	\"items\" : [ { \
	\"collaborative\" : false, \
	\"external_urls\" : { \
	\"spotify\" : \"http://open.spotify.com/user/spotify/playlist/444MDFpUraOidJU5nTYI6n\" \
	}, \
	\"href\" : \"https://api.spotify.com/v1/users/spotify/playlists/444MDFpUraOidJU5nTYI6n\", \
	\"id\" : \"444MDFpUraOidJU5nTYI6n\", \
	\"images\" : [ { \
	\"url\" : \"https://i.scdn.co/image/aadc58aa3422604e41613c2f09f84e648b977578\" \
	} ], \
	\"name\" : \"Young, Wild & Free\", \
	\"owner\" : { \
	\"external_urls\" : { \
	\"spotify\" : \"http://open.spotify.com/user/spotify\" \
	}, \
	\"href\" : \"https://api.spotify.com/v1/users/spotify\", \
	\"id\" : \"spotify\", \
	\"type\" : \"user\", \
	\"uri\" : \"spotify:user:spotify\" \
	}, \
	\"public\" : null, \
	\"tracks\" : { \
	\"href\" : \"https://api.spotify.com/v1/users/spotify/playlists/444MDFpUraOidJU5nTYI6n/tracks\", \
	\"total\" : 105 \
	}, \
	\"type\" : \"playlist\", \
	\"uri\" : \"spotify:user:spotify:playlist:444MDFpUraOidJU5nTYI6n\" \
	} ], \
	\"limit\" : 20, \
	\"next\" : null, \
	\"offset\" : 0, \
	\"previous\" : null, \
	\"total\" : 14 \
	} \
	}";
	
	SPTFeaturedPlaylistList *object = [SPTFeaturedPlaylistList featuredPlaylistListFromData:[response dataUsingEncoding:NSUTF8StringEncoding] withResponse:nil error:nil];

	XCTAssertEqualObjects(@"Need a morning pick-me-up?", object.message);
	XCTAssert(object.message != nil, @"Expected an message");
	XCTAssert(object != nil, @"Expected an object but got nil");
	XCTAssert([object.items count], @"Expected an a non empty list");

	SPTPartialPlaylist *pl = [object.items objectAtIndex:0];
	XCTAssertEqualObjects(pl.name, @"Young, Wild & Free");
}

- (void)testRequestCreation1 {
	NSError *err = nil;
	NSURLRequest *req = [SPTBrowse createRequestForFeaturedPlaylistsInCountry:@"IE" limit:10 offset:0 locale:@"sv_FR" timestamp:[NSDate dateWithTimeIntervalSince1970:999999] accessToken:@"xyz" error:&err];
	
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	
	XCTAssertTrue([req.URL.absoluteString rangeOfString:@"https://api.spotify.com/v1/browse/featured-playlists"].length > 0);
	XCTAssertTrue([req.URL.absoluteString rangeOfString:@"country=IE"].length > 0);
	XCTAssertTrue([req.URL.absoluteString rangeOfString:@"limit=10"].length > 0);
	XCTAssertTrue([req.URL.absoluteString rangeOfString:@"offset=0"].length > 0);
	XCTAssertTrue([req.URL.absoluteString rangeOfString:@"locale=sv_FR"].length > 0);
	
	XCTAssertEqualObjects(req.HTTPMethod, @"GET");
}

- (void)testRequestCreation2 {
	NSError *err = nil;
	NSURLRequest *req = [SPTBrowse createRequestForNewReleasesInCountry:@"ES" limit:33 offset:7 accessToken:@"xyz" error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/browse/new-releases?country=ES&limit=33&offset=7");
	XCTAssertEqualObjects(req.HTTPMethod, @"GET");
}

@end
