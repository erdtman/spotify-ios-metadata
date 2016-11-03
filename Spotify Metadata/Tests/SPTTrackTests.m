/*
 Copyright 2015 Spotify AB
 
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
#import "SPTTrack.h"
#import "SPTPartialArtist.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTTrackTests : XCTestCase

@end

@implementation SPTTrackTests

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

- (void)testLoadTrack
{
	[SPTTrack trackWithURI:[NSURL URLWithString:@"spotify:track:3ehrxAhYms24KLPG8FZe0W"] accessToken:nil market:nil callback:^(NSError *error, SPTTrack *object) {
		XCTAssert(error == nil, @"Got an error trying to create object");
		XCTAssert(object != nil, @"Expected an object but got nil");
		XCTAssert([object isKindOfClass:[SPTTrack class]], @"Was expecting class type SPTTrack, but got %@", NSStringFromClass([object class]));
		XCTAssert([object.name isEqualToString:@"We Are Young (feat. Janelle Monáe) - feat. Janelle Monae"], @"Track name does not match. Was expecting \"We Are Young (feat. Janelle Monáe) - feat. Janelle Monae\" but got %@", object.name);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}


- (void)testTrackProperties
{
	[SPTTrack trackWithURI:[NSURL URLWithString:@"spotify:track:3ehrxAhYms24KLPG8FZe0W"] accessToken:nil market:nil callback:^(NSError *error, SPTTrack *track) {
		XCTAssertEqualObjects(track.name, @"We Are Young (feat. Janelle Monáe) - feat. Janelle Monae", @"Track name does not match. Was expecting \"We Are Young (feat. Janelle Monáe) - feat. Janelle Monae\" but got %@", track.name);
		XCTAssertEqualObjects(track.uri, [NSURL URLWithString:@"spotify:track:3ehrxAhYms24KLPG8FZe0W"], @"URI should be spotify:track:3ehrxAhYms24KLPG8FZe0W, got %@", track.uri);
		XCTAssertEqualObjects(track.sharingURL, [NSURL URLWithString:@"https://open.spotify.com/track/3ehrxAhYms24KLPG8FZe0W"], @"Sharing URL should be https://open.spotify.com/track/3ehrxAhYms24KLPG8FZe0W, got %@", track.sharingURL);
		XCTAssertTrue(track.duration > 0.0, @"Track duration should be greater than 0.0");
		XCTAssertTrue([track.artists count] > 0, @"There should be at least 1 artist");
		XCTAssertTrue([[track.artists filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = 'fun.'"]] count] > 0, @"One of the artists should be \"fun.\"");
		XCTAssertEqualObjects(track.album.name, @"We Are Young (feat. Janelle Monáe)", @"The track's album's name should be \"We Are Young (feat. Janelle Monáe)\", was \"%@\"", track.album.name);
		XCTAssertEqualObjects(track.album.uri, [NSURL URLWithString:@"spotify:album:7dXu1oLf9VPkCsBvXxz4Oe"], @"Track album URI should be spotify:album:7dXu1oLf9VPkCsBvXxz4Oe, got %@", track.album.uri);
		XCTAssert(track.trackNumber == 1, @"Track number should be 1, got %ld", (long)track.trackNumber);
		XCTAssert(track.discNumber == 1, @"Disc number of the track should be 1, got %ld", (long)track.discNumber);
		//		XCTAssertTrue(track.popularity > 0.0, @"Popularity should be greater than 0.0 because this track is hip with the kids");
		XCTAssertFalse(track.flaggedExplicit, @"Track should not be flagged explicit");
		XCTAssertTrue([track.availableTerritories count] > 0, @"Track should be available in at least one territory");
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

- (void)testSmallTrackMultiget {
	NSMutableArray *trackUris = [NSMutableArray array];
	[trackUris addObject:[NSURL URLWithString:@"spotify:track:7umGHsT4iqdUv0eZWcbmuf"]];
	[trackUris addObject:[NSURL URLWithString:@"spotify:track:7beCbOF1ICLYiLl1WRsIXP"]];
	[trackUris addObject:[NSURL URLWithString:@"spotify:track:653MWQvWOfSTtCMZ4gy8WA"]];
	[SPTTrack tracksWithURIs:trackUris accessToken:nil market:nil callback:^(NSError *error, id object) {
		NSArray *trackObjects = (NSArray *)object;
		SPTTrack *track0 = [trackObjects objectAtIndex:0];
		XCTAssertEqualObjects(track0.name, @"Time Of Our Lives");
		
		SPTTrack *track1 = [trackObjects objectAtIndex:1];
		XCTAssertEqualObjects(track1.name, @"Night Force");
		
		SPTTrack *track2 = [trackObjects objectAtIndex:2];
		XCTAssertEqualObjects(track2.name, @"Farraway - Petar Dundov Remix");
		
		XCTAssertTrue(trackObjects.count == 3);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1000.0];
}

- (void)testBigTrackMultiget {
	NSMutableArray *trackUris = [NSMutableArray array];
	for(int i=0; i<2; i++) {
		[trackUris addObject:[NSURL URLWithString:@"spotify:track:7umGHsT4iqdUv0eZWcbmuf"]];
		[trackUris addObject:[NSURL URLWithString:@"spotify:track:7beCbOF1ICLYiLl1WRsIXP"]];
		[trackUris addObject:[NSURL URLWithString:@"spotify:track:653MWQvWOfSTtCMZ4gy8WA"]];
		[trackUris addObject:[NSURL URLWithString:@"spotify:track:7umGHsT4iqdUv0eZWcbmuf"]];
		[trackUris addObject:[NSURL URLWithString:@"spotify:track:7beCbOF1ICLYiLl1WRsIXP"]];
		[trackUris addObject:[NSURL URLWithString:@"spotify:track:653MWQvWOfSTtCMZ4gy8WA"]];
	}
	[SPTTrack tracksWithURIs:trackUris accessToken:nil market:nil callback:^(NSError *error, id object) {
		NSArray *trackObjects = (NSArray *)object;
		for(int i=0; i<2; i++) {
			SPTTrack *track0 = [trackObjects objectAtIndex:i * 6 + 0];
			XCTAssertEqualObjects(track0.name, @"Time Of Our Lives");
			
			SPTTrack *track1 = [trackObjects objectAtIndex:i * 6 + 1];
			XCTAssertEqualObjects(track1.name, @"Night Force");
			
			SPTTrack *track2 = [trackObjects objectAtIndex:i * 6 + 2];
			XCTAssertEqualObjects(track2.name, @"Farraway - Petar Dundov Remix");
		}
		XCTAssertTrue(trackObjects.count == 12);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1000.0];
}

- (void)testTrackParsing {
	NSString *body = @"{"
	"  \"album\" : {"
	"    \"album_type\" : \"album\","
	"    \"external_urls\" : {"
	"      \"spotify\" : \"https://open.spotify.com/album/3Mf52LPa9xo9jmKFOPjbNf\""
	"    },"
	"    \"href\" : \"https://api.spotify.com/v1/albums/3Mf52LPa9xo9jmKFOPjbNf\","
	"    \"id\" : \"3Mf52LPa9xo9jmKFOPjbNf\","
	"    \"images\" : [ {"
	"      \"height\" : 640,"
	"      \"url\" : \"https://i.scdn.co/image/daf3c7c50b3a9aa59f97365bdc96cf5c196c5aff\","
	"      \"width\" : 640"
	"    }, {"
	"      \"height\" : 300,"
	"      \"url\" : \"https://i.scdn.co/image/2582c22cb580a3f3fcf3f63b8f0da2c562fc1578\","
	"      \"width\" : 300"
	"    }, {"
	"      \"height\" : 64,"
	"      \"url\" : \"https://i.scdn.co/image/eca40a38a8d584e3b4b7ac2badd2c758203bc738\","
	"      \"width\" : 64"
	"    } ],"
	"    \"name\" : \"Oleva\","
	"    \"type\" : \"album\","
	"    \"uri\" : \"spotify:album:3Mf52LPa9xo9jmKFOPjbNf\""
	"  },"
	"  \"artists\" : [ {"
	"    \"external_urls\" : {"
	"      \"spotify\" : \"https://open.spotify.com/artist/3eD1hrRRxWBwPsG92vTnht\""
	"    },"
	"    \"href\" : \"https://api.spotify.com/v1/artists/3eD1hrRRxWBwPsG92vTnht\","
	"    \"id\" : \"3eD1hrRRxWBwPsG92vTnht\","
	"    \"name\" : \"Mika Vainio\","
	"    \"type\" : \"artist\","
	"    \"uri\" : \"spotify:artist:3eD1hrRRxWBwPsG92vTnht\""
	"  }, {"
	"    \"external_urls\" : {"
	"      \"spotify\" : \"https://open.spotify.com/artist/6FJvvyzAvJJzxXBfTzz7Xl\""
	"    },"
	"    \"href\" : \"https://api.spotify.com/v1/artists/6FJvvyzAvJJzxXBfTzz7Xl\","
	"    \"id\" : \"6FJvvyzAvJJzxXBfTzz7Xl\","
	"    \"name\" : \"Ø\","
	"    \"type\" : \"artist\","
	"    \"uri\" : \"spotify:artist:6FJvvyzAvJJzxXBfTzz7Xl\""
	"  } ],"
	"  \"disc_number\" : 1,"
	"  \"duration_ms\" : 240373,"
	"  \"explicit\" : false,"
	"  \"external_ids\" : {"
	"    \"isrc\" : \"FISRG0800001\""
	"  },"
	"  \"external_urls\" : {"
	"    \"spotify\" : \"https://open.spotify.com/track/16MAvFtYrTSIm27dhnB7oz\""
	"  },"
	"  \"href\" : \"https://api.spotify.com/v1/tracks/16MAvFtYrTSIm27dhnB7oz\","
	"  \"id\" : \"16MAvFtYrTSIm27dhnB7oz\","
	"  \"is_playable\" : false,"
	"  \"name\" : \"Unien Holvit\","
	"  \"popularity\" : 17,"
	"  \"preview_url\" : \"https://p.scdn.co/mp3-preview/4cc51cda343021b7029a8ecdf7c1d2cc64115382\","
	"  \"track_number\" : 1,"
	"  \"type\" : \"track\","
	"  \"uri\" : \"spotify:track:16MAvFtYrTSIm27dhnB7oz\""
	"}";
	
	NSError *err = nil;
	SPTTrack *track = [SPTTrack trackFromData:[body dataUsingEncoding:NSUTF8StringEncoding] withResponse:nil error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(track);
	
	XCTAssertEqual(track.discNumber, 1);
	XCTAssertEqual(track.popularity, 17);
	XCTAssertEqual(track.duration, 240.373);
	XCTAssertEqual(track.flaggedExplicit, NO);
	XCTAssertEqual(track.hasPlayable, YES);
	XCTAssertEqual(track.isPlayable, NO);
	XCTAssertEqual(track.externalIds.count, 1);
	XCTAssertEqualObjects([track.externalIds objectForKey:@"isrc"], @"FISRG0800001");
	
	XCTAssertEqualObjects(track.identifier, @"16MAvFtYrTSIm27dhnB7oz");
	XCTAssertEqualObjects(track.name, @"Unien Holvit");
	XCTAssertEqualObjects(track.previewURL, [NSURL URLWithString:@"https://p.scdn.co/mp3-preview/4cc51cda343021b7029a8ecdf7c1d2cc64115382"]);
	XCTAssertEqualObjects(track.uri, [NSURL URLWithString:@"spotify:track:16MAvFtYrTSIm27dhnB7oz"]);

	SPTPartialAlbum *album = track.album;
	XCTAssertEqualObjects(album.name, @"Oleva");
	XCTAssertEqualObjects(album.identifier, @"3Mf52LPa9xo9jmKFOPjbNf");
	XCTAssertEqualObjects(album.uri, [NSURL URLWithString:@"spotify:album:3Mf52LPa9xo9jmKFOPjbNf"]);
	XCTAssertEqual(album.covers.count, 3);
	XCTAssertEqual(album.type, SPTAlbumTypeAlbum);

	SPTPartialArtist *artist0 = [track.artists objectAtIndex:0];
	XCTAssertEqualObjects(artist0.name, @"Mika Vainio");
	XCTAssertEqualObjects(artist0.identifier, @"3eD1hrRRxWBwPsG92vTnht");
	XCTAssertEqualObjects(artist0.uri, [NSURL URLWithString:@"spotify:artist:3eD1hrRRxWBwPsG92vTnht"]);
	
	SPTPartialArtist *artist1 = [track.artists objectAtIndex:1];
	XCTAssertEqualObjects(artist1.name, @"Ø");
	XCTAssertEqualObjects(artist1.identifier, @"6FJvvyzAvJJzxXBfTzz7Xl");
	XCTAssertEqualObjects(artist1.uri, [NSURL URLWithString:@"spotify:artist:6FJvvyzAvJJzxXBfTzz7Xl"]);
}

- (void)testMultiTrackParsing {
	NSString *body  = @"{"
	"  \"tracks\" : [ {"
	"    \"explicit\" : true,"
	"    \"href\" : \"https://api.spotify.com/v1/tracks/7ouMYWpwJ422jRcDASZB7P\","
	"    \"id\" : \"7ouMYWpwJ422jRcDASZB7P\","
	"    \"name\" : \"Knights Of Cydonia\","
	"    \"preview_url\" : \"https://p.scdn.co/mp3-preview/2b6c3895a06c1d5e0638c88f8b035dff1d1d4831\","
	"    \"type\" : \"track\","
	"    \"uri\" : \"spotify:track:7ouMYWpwJ422jRcDASZB7P\""
	"  }, {"
	"    \"explicit\" : false,"
	"    \"href\" : \"https://api.spotify.com/v1/tracks/4VqPOruhp5EdPBeR92t6lQ\","
	"    \"id\" : \"4VqPOruhp5EdPBeR92t6lQ\","
	"    \"is_playable\" : false,"
	"    \"name\" : \"Uprising\","
	"    \"preview_url\" : \"https://p.scdn.co/mp3-preview/4fcb9dc0aa51f0f5e4f95ef550a813a89d9c395d\","
	"    \"type\" : \"track\","
	"    \"uri\" : \"spotify:track:4VqPOruhp5EdPBeR92t6lQ\""
	"  }, {"
	"    \"explicit\" : false,"
	"    \"href\" : \"https://api.spotify.com/v1/tracks/2takcwOaAZWiXQijPHIx7B\","
	"    \"id\" : \"2takcwOaAZWiXQijPHIx7B\","
	"    \"is_playable\" : true,"
	"    \"name\" : \"Time Is Running Out\","
	"    \"track_number\" : 3,"
	"    \"type\" : \"track\","
	"    \"uri\" : \"spotify:track:2takcwOaAZWiXQijPHIx7B\""
	"  } ]"
	"}";
	
	NSError *err = nil;
	NSArray *tracks = [SPTTrack tracksFromData:[body dataUsingEncoding:NSUTF8StringEncoding] withResponse:nil error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(tracks);
	XCTAssertEqual(3, tracks.count);

	SPTTrack *track0 = [tracks objectAtIndex:0];
	XCTAssertNotNil(track0);
	XCTAssertEqual(track0.flaggedExplicit, YES);
	XCTAssertEqual(track0.hasPlayable, NO);
	XCTAssertEqual(track0.isPlayable, YES);
	XCTAssertEqualObjects(track0.name, @"Knights Of Cydonia");
	XCTAssertEqualObjects(track0.identifier, @"7ouMYWpwJ422jRcDASZB7P");
	
	SPTTrack *track1 = [tracks objectAtIndex:1];
	XCTAssertNotNil(track1);
	XCTAssertEqual(track1.flaggedExplicit, NO);
	XCTAssertEqual(track1.hasPlayable, YES);
	XCTAssertEqual(track1.isPlayable, NO);
	XCTAssertEqualObjects(track1.name, @"Uprising");
	XCTAssertEqualObjects(track1.identifier, @"4VqPOruhp5EdPBeR92t6lQ");
	
	SPTTrack *track2 = [tracks objectAtIndex:2];
	XCTAssertNotNil(track2);
	XCTAssertEqual(track2.flaggedExplicit, NO);
	XCTAssertEqual(track2.hasPlayable, YES);
	XCTAssertEqual(track2.isPlayable, YES);
	XCTAssertEqualObjects(track2.name, @"Time Is Running Out");
	XCTAssertEqualObjects(track2.identifier, @"2takcwOaAZWiXQijPHIx7B");
	
}

@end
