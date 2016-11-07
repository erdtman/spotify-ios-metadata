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
#import "SPTListPage.h"
#import "SPTPartialTrack.h"
#import "SPTYourMusic.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTYourMusicTests : XCTestCase

@end

@implementation SPTYourMusicTests

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

- (void)testParsingSavedTracks
{
	NSString *response = @"{"
	"  \"href\" : \"https://api.spotify.com/v1/me/tracks?offset=7&limit=3&market=ES\","
	"  \"items\" : [ {"
	"    \"added_at\" : \"2015-04-17T19:36:48Z\","
	"    \"track\" : {"
	"      \"href\" : \"https://api.spotify.com/v1/tracks/7tsX9Orv7aKjhUgnGXfJgh\","
	"      \"id\" : \"7tsX9Orv7aKjhUgnGXfJgh\","
	"      \"is_playable\" : true,"
	"      \"name\" : \"Tempura - Original\","
	"      \"popularity\" : 27,"
	"      \"preview_url\" : \"https://p.scdn.co/mp3-preview/0736803b6ff68310e9163c14546abc214cc920a9\","
	"      \"track_number\" : 2,"
	"      \"type\" : \"track\","
	"      \"uri\" : \"spotify:track:7tsX9Orv7aKjhUgnGXfJgh\""
	"    }"
	"  }, {"
	"    \"added_at\" : \"2015-04-17T19:01:56Z\","
	"    \"track\" : {"
	"      \"href\" : \"https://api.spotify.com/v1/tracks/6lDsWYDjwRQVM2WRb4epDf\","
	"      \"id\" : \"6lDsWYDjwRQVM2WRb4epDf\","
	"      \"is_playable\" : true,"
	"      \"name\" : \"Solaris\","
	"      \"popularity\" : 19,"
	"      \"preview_url\" : \"https://p.scdn.co/mp3-preview/6b67b99aefe7a084ea2765fd8301b277529f12d4\","
	"      \"track_number\" : 4,"
	"      \"type\" : \"track\","
	"      \"uri\" : \"spotify:track:6lDsWYDjwRQVM2WRb4epDf\""
	"    }"
	"  }, {"
	"    \"added_at\" : \"2015-04-17T16:26:33Z\","
	"    \"track\" : {"
	"      \"href\" : \"https://api.spotify.com/v1/tracks/6q9rDJ7xoBeXsSaQENE5lu\","
	"      \"id\" : \"6q9rDJ7xoBeXsSaQENE5lu\","
	"      \"is_playable\" : true,"
	"      \"name\" : \"Always Something Better\","
	"      \"popularity\" : 9,"
	"      \"preview_url\" : \"https://p.scdn.co/mp3-preview/4ef43870358deb18b26e2cba7730778e0870ced6\","
	"      \"track_number\" : 7,"
	"      \"type\" : \"track\","
	"      \"uri\" : \"spotify:track:6q9rDJ7xoBeXsSaQENE5lu\""
	"    }"
	"  } ],"
	"  \"limit\" : 3,"
	"  \"next\" : \"https://api.spotify.com/v1/me/tracks?offset=10&limit=3&market=ES\","
	"  \"offset\" : 7,"
	"  \"previous\" : \"https://api.spotify.com/v1/me/tracks?offset=4&limit=3&market=ES\","
	"  \"total\" : 663"
	"}";
	
	NSError *err = nil;
	SPTListPage *page = [SPTListPage listPageFromData:[response dataUsingEncoding:NSUTF8StringEncoding]
										 withResponse:nil
							 expectingPartialChildren:NO
										rootObjectKey:nil error:&err];
	
	XCTAssertNil(err);
	XCTAssertNotNil(page);
	
	SPTPartialTrack *track0 = [page.items objectAtIndex:0];
	XCTAssertEqualObjects(track0.name, @"Tempura - Original");
	XCTAssertEqualObjects(track0.uri, [NSURL URLWithString:@"spotify:track:7tsX9Orv7aKjhUgnGXfJgh"]);

	SPTPartialTrack *track1 = [page.items objectAtIndex:1];
	XCTAssertEqualObjects(track1.name, @"Solaris");
	XCTAssertEqualObjects(track1.uri, [NSURL URLWithString:@"spotify:track:6lDsWYDjwRQVM2WRb4epDf"]);

	SPTPartialTrack *track2 = [page.items objectAtIndex:2];
	XCTAssertEqualObjects(track2.name, @"Always Something Better");
	XCTAssertEqualObjects(track2.uri, [NSURL URLWithString:@"spotify:track:6q9rDJ7xoBeXsSaQENE5lu"]);
}

- (void)testRequestCreation1 {
	NSError *err = nil;
	NSURLRequest *req = [SPTYourMusic createRequestForCheckingIfSavedTracksContains:@[
																					  [NSURL URLWithString:@"spotify:track:7tsX9Orv7aKjhUgnGXfJgh"],
																					  [NSURL URLWithString:@"spotify:track:6q9rDJ7xoBeXsSaQENE5lu"]
																					  ]
															 forUserWithAccessToken:@"xyz"
																			  error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/me/tracks/contains?ids=7tsX9Orv7aKjhUgnGXfJgh%2C6q9rDJ7xoBeXsSaQENE5lu");
	XCTAssertEqualObjects(req.HTTPMethod, @"GET");
}

- (void)testRequestCreation2 {
	NSError *err = nil;
	NSURLRequest *req = [SPTYourMusic createRequestForCurrentUsersSavedTracksWithAccessToken:@"zzxx"
																					   error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/me/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"GET");
}

- (void)testRequestCreation3 {
	NSError *err = nil;
	NSURLRequest *req = [SPTYourMusic createRequestForRemovingTracksFromSaved:@[
																				[NSURL URLWithString:@"spotify:track:abc123"]
																				]
													   forUserWithAccessToken:@"xyz"
																		error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/me/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"DELETE");
	NSString *body = [[NSString alloc] initWithData:req.HTTPBody encoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects(body, @"[\n  \"abc123\"\n]");
}

- (void)testRequestCreation4 {
	NSError *err = nil;
	NSURLRequest *req = [SPTYourMusic createRequestForSavingTracks:@[
																	 [NSURL URLWithString:@"spotify:track:6q9rDJ7xoBeXsSaQENE5lu"],
																	 [NSURL URLWithString:@"spotify:track:6lDsWYDjwRQVM2WRb4epDf"]
																	 ]
											forUserWithAccessToken:@"zyz"
															 error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/me/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"PUT");
	NSString *body = [[NSString alloc] initWithData:req.HTTPBody encoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects(body, @"[\n  \"6q9rDJ7xoBeXsSaQENE5lu\",\n  \"6lDsWYDjwRQVM2WRb4epDf\"\n]");
}

@end
