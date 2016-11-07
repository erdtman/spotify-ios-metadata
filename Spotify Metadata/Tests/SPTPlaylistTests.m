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

#import "SPTRequest.h"
#import "SPTPlayListList.h"
#import "SPTPlayListSnapshot.h"
#import "SPTTrack.h"
#import "SPTUser.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTPlaylistTests : XCTestCase<SPTRequestHandlerProtocol>

@end

@implementation SPTPlaylistTests {
	NSString *mockResponse;
	NSURLRequest *lastRequest;
}

- (void)setUp
{
	[super setUp];
	// Put setup code here; it will be run once, before the first test case.
	[SPTRequest setSharedHandler:self];
}

- (void)tearDown
{
	// Put teardown code here; it will be run once, after the last test case.
	[super tearDown];
	[SPTRequest setSharedHandler:nil];
}

- (void)performRequest:(NSURLRequest *)request callback:(SPTRequestDataCallback)block {
	lastRequest = request;
	if (mockResponse != nil) {
		block(nil, nil, [mockResponse dataUsingEncoding:NSUTF8StringEncoding]);
		mockResponse = nil;
	} else {
		block([NSError errorWithDomain:@"SomeError" code:404 userInfo:nil], nil, nil);
	}
}

- (void)testPlaylistMultiget {
	[SPTRequest setSharedHandler:self];
	
	mockResponse = @"{\
	\"collaborative\" : false,\
	\"description\" : \"A playlist for testing\",\
	\"external_urls\" : {\
	\"spotify\" : \"http://open.spotify.com/user/jmperezperez/playlist/3cEYpjA9oz9GiPac4AsH4n\"\
	},\
	\"followers\" : {\
	\"href\" : null,\
	\"total\" : 6\
	},\
	\"href\" : \"https://api.spotify.com/v1/users/jmperezperez/playlists/3cEYpjA9oz9GiPac4AsH4n\",\
	\"id\" : \"3cEYpjA9oz9GiPac4AsH4n\",\
	\"images\" : [ {\
	\"height\" : null,\
	\"url\" : \"https://u.scdn.co/images/pl/default/15e1e401aca06139b92bb116834a8324d03d4fd1\",\
	\"width\" : null\
	} ],\
	\"name\" : \"Spotify Web API Testing playlist\",\
	\"owner\" : {\
	\"external_urls\" : {\
	\"spotify\" : \"http://open.spotify.com/user/jmperezperez\"\
	},\
	\"href\" : \"https://api.spotify.com/v1/users/jmperezperez\",\
	\"id\" : \"jmperezperez\",\
	\"type\" : \"user\",\
	\"uri\" : \"spotify:user:jmperezperez\"\
	},\
	\"public\" : true,\
	\"snapshot_id\" : \"OO6GcckxJ416i8dVUSXH0xscQyX6CwEP14rp5JH+nM/Yd6YA9HTuT7F39uC6Y6MJ\",\
	\"tracks\" : {\
	\"href\" : \"https://api.spotify.com/v1/users/jmperezperez/playlists/3cEYpjA9oz9GiPac4AsH4n/tracks?offset=0&limit=100\",\
	\"items\" : [ {\
	\"added_at\" : \"2015-01-15T12:39:22Z\",\
	\"added_by\" : {\
	\"external_urls\" : {\
	\"spotify\" : \"http://open.spotify.com/user/jmperezperez\"\
	},\
	\"href\" : \"https://api.spotify.com/v1/users/jmperezperez\",\
	\"id\" : \"jmperezperez\",\
	\"type\" : \"user\",\
	\"uri\" : \"spotify:user:jmperezperez\"\
	},\
	\"is_local\" : false,\
	\"track\" : {\
	\"album\" : {\
	\"album_type\" : \"album\",\
	\"available_markets\" : [ \"ES\", \"SE\" ],\
	\"external_urls\" : {\
	\"spotify\" : \"https://open.spotify.com/album/2pANdqPvxInB0YvcDiw4ko\"\
	},\
	\"href\" : \"https://api.spotify.com/v1/albums/2pANdqPvxInB0YvcDiw4ko\",\
	\"id\" : \"2pANdqPvxInB0YvcDiw4ko\",\
	\"images\" : [],\
	\"name\" : \"Progressive Psy Trance Picks Vol.8\",\
	\"type\" : \"album\",\
	\"uri\" : \"spotify:album:2pANdqPvxInB0YvcDiw4ko\"\
	},\
	\"artists\" : [ {\
	\"external_urls\" : {\
	\"spotify\" : \"https://open.spotify.com/artist/6eSdhw46riw2OUHgMwR8B5\"\
	},\
	\"href\" : \"https://api.spotify.com/v1/artists/6eSdhw46riw2OUHgMwR8B5\",\
	\"id\" : \"6eSdhw46riw2OUHgMwR8B5\",\
	\"name\" : \"Odiseo\",\
	\"type\" : \"artist\",\
	\"uri\" : \"spotify:artist:6eSdhw46riw2OUHgMwR8B5\"\
	} ],\
	\"available_markets\" : [ \"UY\" ],\
	\"disc_number\" : 1,\
	\"duration_ms\" : 376000,\
	\"explicit\" : false,\
	\"external_ids\" : {\
	\"isrc\" : \"DEKC41200989\"\
	},\
	\"external_urls\" : {\
	\"spotify\" : \"https://open.spotify.com/track/4rzfv0JLZfVhOhbSQ8o5jZ\"\
	},\
	\"href\" : \"https://api.spotify.com/v1/tracks/4rzfv0JLZfVhOhbSQ8o5jZ\",\
	\"id\" : \"4rzfv0JLZfVhOhbSQ8o5jZ\",\
	\"name\" : \"Api\",\
	\"popularity\" : 8,\
	\"preview_url\" : \"https://p.scdn.co/mp3-preview/9a149a9366c5bcb3e8b947b00f26e74be7b8aca6\",\
	\"track_number\" : 10,\
	\"type\" : \"track\",\
	\"uri\" : \"spotify:track:4rzfv0JLZfVhOhbSQ8o5jZ\"\
	}\
	} ],\
	\"limit\" : 100,\
	\"next\" : null,\
	\"offset\" : 0,\
	\"previous\" : null,\
	\"total\" : 1\
	},\
	\"type\" : \"playlist\",\
	\"uri\" : \"spotify:user:jmperezperez:playlist:3cEYpjA9oz9GiPac4AsH4n\"\
	}";
	
	[SPTPlaylistSnapshot playlistWithURI:[NSURL URLWithString:@"spotify:user:possan:playlist:0YlbYQoIH8oViGlTrkFsvz"] accessToken:nil callback:^(NSError *error, id object) {
		/* NSArray *array = (NSArray *)object;
		 */
		SPTPlaylistSnapshot *playlist1 = object;
		XCTAssertEqualObjects(playlist1.name, @"Spotify Web API Testing playlist");
		XCTAssertEqual(playlist1.tracksForPlayback.count, 1);
		SPTTrack *track0 = [playlist1.tracksForPlayback objectAtIndex:0];
		XCTAssertEqualObjects(track0.name, @"Api");
		XCTAssertEqualObjects(track0.previewURL.absoluteString, @"https://p.scdn.co/mp3-preview/9a149a9366c5bcb3e8b947b00f26e74be7b8aca6");
		
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1000.0];
	
	XCTAssert(true);
}

- (void)testPlaylistListParsing {
	NSString *body = @"{"
	"  \"href\" : \"https://api.spotify.com/v1/users/possan/playlists?offset=0&limit=2\","
	"  \"items\" : [ {"
	"    \"collaborative\" : false,"
	"    \"external_urls\" : {"
	"      \"spotify\" : \"http://open.spotify.com/user/squarepushermusic/playlist/31HBcw54FawC29wnSs6Zj1\""
	"    },"
	"    \"href\" : \"https://api.spotify.com/v1/users/squarepushermusic/playlists/31HBcw54FawC29wnSs6Zj1\","
	"    \"id\" : \"31HBcw54FawC29wnSs6Zj1\","
	"    \"images\" : [ {"
	"      \"height\" : 300,"
	"      \"url\" : \"https://i.scdn.co/image/126a758e6e4fc0b86891074527c45d2163d2434d\","
	"      \"width\" : 300"
	"    } ],"
	"    \"name\" : \"Select Squarepusher\","
	"    \"owner\" : {"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"http://open.spotify.com/user/squarepushermusic\""
	"      },"
	"      \"href\" : \"https://api.spotify.com/v1/users/squarepushermusic\","
	"      \"id\" : \"squarepushermusic\","
	"      \"type\" : \"user\","
	"      \"uri\" : \"spotify:user:squarepushermusic\""
	"    },"
	"    \"public\" : true,"
	"    \"tracks\" : {"
	"      \"href\" : \"https://api.spotify.com/v1/users/squarepushermusic/playlists/31HBcw54FawC29wnSs6Zj1/tracks\","
	"      \"total\" : 17"
	"    },"
	"    \"type\" : \"playlist\","
	"    \"uri\" : \"spotify:user:squarepushermusic:playlist:31HBcw54FawC29wnSs6Zj1\""
	"  }, {"
	"    \"collaborative\" : false,"
	"    \"external_urls\" : {"
	"      \"spotify\" : \"http://open.spotify.com/user/spotify/playlist/3iHRYohH2ULAbDXvj2EhvL\""
	"    },"
	"    \"href\" : \"https://api.spotify.com/v1/users/spotify/playlists/3iHRYohH2ULAbDXvj2EhvL\","
	"    \"id\" : \"3iHRYohH2ULAbDXvj2EhvL\","
	"    \"images\" : [ {"
	"      \"height\" : 300,"
	"      \"url\" : \"https://i.scdn.co/image/0874cc7be450f8f852e8dde953e662d648fe96f6\","
	"      \"width\" : 300"
	"    } ],"
	"    \"name\" : \"Discover Weekly\","
	"    \"owner\" : {"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"http://open.spotify.com/user/spotify\""
	"      },"
	"      \"href\" : \"https://api.spotify.com/v1/users/spotify\","
	"      \"id\" : \"spotify\","
	"      \"type\" : \"user\","
	"      \"uri\" : \"spotify:user:spotify\""
	"    },"
	"    \"public\" : false,"
	"    \"tracks\" : {"
	"      \"href\" : \"https://api.spotify.com/v1/users/spotify/playlists/3iHRYohH2ULAbDXvj2EhvL/tracks\","
	"      \"total\" : 30"
	"    },"
	"    \"type\" : \"playlist\","
	"    \"uri\" : \"spotify:user:spotify:playlist:3iHRYohH2ULAbDXvj2EhvL\""
	"  } ],"
	"  \"limit\" : 2,"
	"  \"next\" : \"https://api.spotify.com/v1/users/possan/playlists?offset=2&limit=2\","
	"  \"offset\" : 0,"
	"  \"previous\" : null,"
	"  \"total\" : 241"
	"}";
	
	SPTPlaylistList *list = [SPTPlaylistList playlistListFromData:[body dataUsingEncoding:NSUTF8StringEncoding] withResponse:nil error:nil];
	XCTAssertEqual(list.items.count, 2);
	
	SPTPartialPlaylist *playlist0 = [list.items objectAtIndex:0];
	XCTAssertEqualObjects(playlist0.name, @"Select Squarepusher");
	XCTAssertEqualObjects(playlist0.uri, [NSURL URLWithString: @"spotify:user:squarepushermusic:playlist:31HBcw54FawC29wnSs6Zj1"]);
	XCTAssertEqualObjects(playlist0.largestImage.imageURL, [NSURL URLWithString:@"https://i.scdn.co/image/126a758e6e4fc0b86891074527c45d2163d2434d"]);
	XCTAssertEqual(playlist0.largestImage.size.width, 300);
	XCTAssertEqual(playlist0.trackCount, 17);
	XCTAssertEqual(playlist0.isPublic, YES);
	XCTAssertEqualObjects(playlist0.owner.canonicalUserName, @"squarepushermusic");

	SPTPartialPlaylist *playlist1 = [list.items objectAtIndex:1];
	XCTAssertEqualObjects(playlist1.name, @"Discover Weekly");
	XCTAssertEqualObjects(playlist1.uri, [NSURL URLWithString:@"spotify:user:spotify:playlist:3iHRYohH2ULAbDXvj2EhvL"]);
	XCTAssertEqualObjects(playlist1.largestImage.imageURL, [NSURL URLWithString:@"https://i.scdn.co/image/0874cc7be450f8f852e8dde953e662d648fe96f6"]);
	XCTAssertEqual(playlist1.largestImage.size.height, 300);
	XCTAssertEqual(playlist1.trackCount, 30);
	XCTAssertEqual(playlist1.isPublic, NO);
	XCTAssertEqualObjects(playlist1.owner.canonicalUserName, @"spotify");
}

- (void) testCreatePlaylistRequest1 {
	NSError *err = nil;
	NSURLRequest *req = [SPTPlaylistList createRequestForCreatingPlaylistWithName:@"testo"
																		  forUser:@"åäö"
																   withPublicFlag:YES
																	  accessToken:@"xyz123"
																			error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/%C3%A5%C3%A4%C3%B6/playlists");
	XCTAssertEqualObjects(req.HTTPMethod, @"POST");
	
	NSDictionary *decodedBody = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	XCTAssertEqualObjects([decodedBody objectForKey:@"name"], @"testo");
	XCTAssertEqualObjects([decodedBody objectForKey:@"public"], [NSNumber numberWithBool:YES]);

}

- (void) testCreatePlaylistRequest2 {
	NSError *err = nil;
	NSURLRequest *req = [SPTPlaylistList createRequestForCreatingPlaylistWithName:@"abc 123 åäö"
																		  forUser:@"possan"
																   withPublicFlag:NO
																	  accessToken:@"xyz123"
																			error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/possan/playlists");
	XCTAssertEqualObjects(req.HTTPMethod, @"POST");
	
	NSDictionary *decodedBody = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	XCTAssertEqualObjects([decodedBody objectForKey:@"name"], @"abc 123 åäö");
	XCTAssertEqualObjects([decodedBody objectForKey:@"public"], [NSNumber numberWithBool:NO]);

}




- (void) testRemoveTracksRequest {
	NSError *err = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForRemovingTracks:@[
																			[NSURL URLWithString:@"spotify:track:a"],
																			[NSURL URLWithString:@"spotify:track:b"]
																			]
															 fromPlaylist:[NSURL URLWithString:@"spotify:user:username:playlist:playlistid"]
														  withAccessToken:@"xyz123"
																 snapshot:@"snapshot123" error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/username/playlists/playlistid/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"DELETE");
	
	NSDictionary *decodedBody = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	XCTAssertEqualObjects([decodedBody objectForKey:@"snapshot_id"], @"snapshot123");
	NSArray *tracks = [decodedBody objectForKey:@"tracks"];
	NSDictionary *track0 = [tracks objectAtIndex:0];
	XCTAssertEqualObjects([track0 objectForKey:@"uri"], @"spotify:track:a");
	NSDictionary *track1 = [tracks objectAtIndex:1];
	XCTAssertEqualObjects([track1 objectForKey:@"uri"], @"spotify:track:b");
}

- (void) testAddTracksRequest1 {
	NSError *err = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForAddingTracks:@[
																			[NSURL URLWithString:@"spotify:track:a"],
																			[NSURL URLWithString:@"spotify:track:b"]
																			]
						 
															   atPosition:0
															   toPlaylist:[NSURL URLWithString:@"spotify:user:username:playlist:playlistid"]
														  withAccessToken:@"xyz123"
																	error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/username/playlists/playlistid/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"POST");
	
	NSDictionary *decodedBody = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	XCTAssertEqualObjects([decodedBody objectForKey:@"position"], @(0));
	NSArray *tracks = [decodedBody objectForKey:@"uris"];
	XCTAssertEqualObjects([tracks objectAtIndex:0], @"spotify:track:a");
	XCTAssertEqualObjects([tracks objectAtIndex:1], @"spotify:track:b");
}

- (void) testAddTracksRequest2 {
	NSError *err = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForAddingTracks:@[
																			[NSURL URLWithString:@"spotify:track:a"],
																			[NSURL URLWithString:@"spotify:track:b"]
																			]
															   toPlaylist:[NSURL URLWithString:@"spotify:user:username:playlist:playlistid"]
														  withAccessToken:@"xyz123"
																	error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/username/playlists/playlistid/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"POST");

	NSArray *tracks = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	XCTAssertEqualObjects([tracks objectAtIndex:0], @"spotify:track:a");
	XCTAssertEqualObjects([tracks objectAtIndex:1], @"spotify:track:b");
}



- (void) testRemoveTracksRequest1 {
	NSError *err = nil;
	
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForRemovingTracks:@[
																			  [NSURL URLWithString:@"spotify:track:a"],
																			  [NSURL URLWithString:@"spotify:track:b"]
																			  ]
															   fromPlaylist:[NSURL URLWithString:@"spotify:user:username:playlist:playlistid"]
															withAccessToken:@"xyz123"
						 
																   snapshot:@"snapshot123"
																	  error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/username/playlists/playlistid/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"DELETE");
	
	NSDictionary *decodedBody = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	XCTAssertEqualObjects([decodedBody objectForKey:@"snapshot_id"], @"snapshot123");
	NSArray *tracks = [decodedBody objectForKey:@"tracks"];
	NSDictionary *track0 = [tracks objectAtIndex:0];
	XCTAssertEqualObjects([track0 objectForKey:@"uri"], @"spotify:track:a");
	NSDictionary *track1 = [tracks objectAtIndex:1];
	XCTAssertEqualObjects([track1 objectForKey:@"uri"], @"spotify:track:b");
}

- (void) testRemoveTracksRequest2 {
	NSError *err = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForRemovingTracksWithPositions:@[
																						   @{
																							   @"track": [NSURL URLWithString:@"spotify:track:a"],
																							   @"positions": @[ @(3) ]
																							   },
																						   @{
																							   @"track": [NSURL URLWithString:@"spotify:track:b"],
																							   @"positions": @[ @(5), @(6) ]
																							   }
																						   ]
																			fromPlaylist:[NSURL URLWithString:@"spotify:user:username:playlist:playlistid"]
																		withAccessToken:@"xyz123"
																				snapshot:@"snapshot!"
																				   error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/username/playlists/playlistid/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"DELETE");

	NSDictionary *decodedBody = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	XCTAssertEqualObjects([decodedBody objectForKey:@"snapshot_id"], @"snapshot!");
	NSArray *tracks = [decodedBody objectForKey:@"tracks"];
	
	NSDictionary *track0 = [tracks objectAtIndex:0];
	XCTAssertEqualObjects([track0 objectForKey:@"uri"], @"spotify:track:a");
	NSArray *positions0 = [track0 objectForKey:@"positions"];
	XCTAssertEqualObjects([positions0 objectAtIndex:0], @(3));

	NSDictionary *track1 = [tracks objectAtIndex:1];
	XCTAssertEqualObjects([track1 objectForKey:@"uri"], @"spotify:track:b");
	NSArray *positions1 = [track1 objectForKey:@"positions"];
	XCTAssertEqualObjects([positions1 objectAtIndex:0], @(5));
	XCTAssertEqualObjects([positions1 objectAtIndex:1], @(6));
}




- (void) testChangingDetailsRequest1 {
	NSError *err = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForChangingDetails:@{
																			   @"name": @"New name!",
																			   @"public": @(false)
																			   }
																  inPlaylist:[NSURL URLWithString:@"spotify:user:username234:playlist:playlistid123"]
															 withAccessToken:@"xyz123"
																	   error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/username234/playlists/playlistid123");
	XCTAssertEqualObjects(req.HTTPMethod, @"PUT");
	
	NSDictionary *decodedBody = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	XCTAssertEqualObjects([decodedBody objectForKey:@"name"], @"New name!");
	XCTAssertEqualObjects([decodedBody objectForKey:@"public"], [NSNumber numberWithBool:NO]);
}



- (void) testReplaceTracksRequest1 {
	NSError *err = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForSettingTracks:@[
																			[NSURL URLWithString:@"spotify:track:a"],
																			[NSURL URLWithString:@"spotify:track:b"]
																			]
																inPlaylist:[NSURL URLWithString:@"spotify:user:username:playlist:playlistid"]
														   withAccessToken:@"xyz123"
																	 error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(req);
	XCTAssertEqualObjects(req.URL.absoluteString, @"https://api.spotify.com/v1/users/username/playlists/playlistid/tracks");
	XCTAssertEqualObjects(req.HTTPMethod, @"PUT");
	
	NSDictionary *decodedBody = [NSJSONSerialization JSONObjectWithData:req.HTTPBody options:0 error:nil];
	NSArray *tracks = [decodedBody objectForKey:@"uris"];
	XCTAssertEqualObjects([tracks objectAtIndex:0], @"spotify:track:a");
	XCTAssertEqualObjects([tracks objectAtIndex:1], @"spotify:track:b");
}


@end
