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

#import "SPTAlbum.h"
#import "SPTRequest.h"
#import "SPTListPage.h"
#import "SPTImage.h"
#import "SPTPartialTrack.h"
#import "SPTPartialArtist.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTAlbumTests : XCTestCase

@end

@implementation SPTAlbumTests

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

- (void)testLoadAlbum
{
	[SPTAlbum albumWithURI:[NSURL URLWithString:@"spotify:album:4pFJNfXVsVD1PMJhfuZ9ET"] accessToken:nil market:nil callback:^(NSError *error, SPTAlbum *object) {
		XCTAssert(error == nil, @"Got error while loading Album: %@", error);
		XCTAssert(object != nil, @"Expected an object, got nil");
		XCTAssert([object isKindOfClass:[SPTAlbum class]], @"Expected class type SPTAlbum but got %@", NSStringFromClass([object class]));
		XCTAssert([object.name isEqualToString:@"Picaresque"], @"Expected name to be \"Picaresque\" but got %@", object.name);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

- (void)testAlbumProperties
{
	[SPTAlbum albumWithURI:[NSURL URLWithString:@"spotify:album:2nTJqljt4gL1lJgtFfG4Aq"] accessToken:nil market:nil callback:^(NSError *error, SPTAlbum *album) {
		NSDateComponents *components = [[NSCalendar currentCalendar] components:kCFCalendarUnitDay|kCFCalendarUnitMonth|kCFCalendarUnitYear fromDate:album.releaseDate];
		
		XCTAssert([album.name isEqualToString:@"What?!"], @"Name should be \"What?!\" (got \"%@\")", album.name);
		XCTAssert([[album.uri absoluteString] isEqualToString:@"spotify:album:2nTJqljt4gL1lJgtFfG4Aq"], @"URI should be spotify:album:2nTJqljt4gL1lJgtFfG4Aq (got %@)", album.uri);
		XCTAssert([[album.sharingURL absoluteString] isEqualToString:@"https://open.spotify.com/album/2nTJqljt4gL1lJgtFfG4Aq"], @"sharingURL should be https://open.spotify.com/album/2nTJqljt4gL1lJgtFfG4Aq (got %@)", album.sharingURL);
		XCTAssert([album.availableTerritories count] == 0, @"There should be available territories");
		XCTAssert([album.artists count] > 0, @"There should be at least one artist");
		XCTAssert([[album.artists filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = 'William Onyeabor'"]] count] > 0, "William Onyeabor should be one of the artists");
		XCTAssert([album.firstTrackPage.items count] == 10, @"There should be 10 tracks");
		XCTAssert([[album.firstTrackPage.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = 'Atomic Bomb - Cover'"]] count] > 0, "Atomic Bomb should be one of the tracks");
		XCTAssert(components.year == 2014, @"Release year should be 2014");
		XCTAssert(components.month == 4, @"Release month should be 4");
		XCTAssert(components.day == 28, @"Release day should be 28");
		XCTAssert(album.type == SPTAlbumTypeCompilation, @"Album type should be SPTAlbumTypeAlbum");
		XCTAssert([album.genres isKindOfClass:[NSArray class]], @"Genres should be an NSArray");
		XCTAssert([album.covers isKindOfClass:[NSArray class]], @"Covers should be an NSArray");
		XCTAssert([album.covers count] > 0, @"There should be at least one cover image");
		XCTAssert(album.largestCover.size.width > album.smallestCover.size.width, @"Largest cover should be wider than smallest cover");
		XCTAssert(album.popularity > 0.0, @"It should be more popular than 0.0, or there's no justice in this world");
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

- (void)testAlbumMultiget {
	NSMutableArray *trackUris = [NSMutableArray array];
	[trackUris addObject:[NSURL URLWithString:@"spotify:album:5CYirz4tCpdKaJzaQWqgH9"]];
	[trackUris addObject:[NSURL URLWithString:@"spotify:album:4wJmWEuo2ezowJeJVdQWYS"]];

	[SPTAlbum albumsWithURIs:trackUris accessToken:nil market:nil callback:^(NSError *error, id object) {
		NSArray *array = (NSArray *)object;
		
		SPTAlbum *album0 = [array objectAtIndex:0];
		XCTAssertEqualObjects(album0.name, @"Interceptor");
		
		SPTAlbum *album1 = [array objectAtIndex:1];
		XCTAssertEqualObjects(album1.name, @"Burning Chrome");
		
		XCTAssertTrue(array.count == 2);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1000.0];
}

- (void)testAlbumMutipageMultiget {
	NSMutableArray *trackUris = [NSMutableArray array];
	[trackUris addObject:[NSURL URLWithString:@"spotify:album:5CYirz4tCpdKaJzaQWqgH9"]];
	[trackUris addObject:[NSURL URLWithString:@"spotify:album:4wJmWEuo2ezowJeJVdQWYS"]];
	[trackUris addObject:[NSURL URLWithString:@"spotify:album:5CYirz4tCpdKaJzaQWqgH9"]];
	[trackUris addObject:[NSURL URLWithString:@"spotify:album:4wJmWEuo2ezowJeJVdQWYS"]];
	[trackUris addObject:[NSURL URLWithString:@"spotify:album:5CYirz4tCpdKaJzaQWqgH9"]];

	[SPTAlbum albumsWithURIs:trackUris accessToken:nil market:nil callback:^(NSError *error, id object) {
		NSArray *array = (NSArray *)object;
		
		SPTAlbum *album0 = [array objectAtIndex:0];
		XCTAssertEqualObjects(album0.name, @"Interceptor");
		
		SPTAlbum *album1 = [array objectAtIndex:1];
		XCTAssertEqualObjects(album1.name, @"Burning Chrome");
		
		XCTAssertTrue(array.count == trackUris.count);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1000.0];
}

- (void)testCreateAlbumRequest1 {
	NSError *err = nil;
	NSURLRequest *req = [SPTAlbum createRequestForAlbum:[NSURL URLWithString:@"spotify:album:6vuaXr9FgaT03zUMSRGU2Z"] withAccessToken:nil market:@"ES" error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/albums/6vuaXr9FgaT03zUMSRGU2Z?market=ES", @"URL should be correct.");
}

- (void)testCreateAlbumsRequest {
	NSError *err = nil;
	NSURLRequest *req = [SPTAlbum createRequestForAlbums:@[
														   [NSURL URLWithString:@"spotify:album:6vuaXr9FgaT03zUMSRGU2Z"],
														   [NSURL URLWithString:@"spotify:album:0IslpxQHkGCdMnfcRtvvaB"]
														   ] withAccessToken:nil market:nil error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/albums?ids=6vuaXr9FgaT03zUMSRGU2Z%2C0IslpxQHkGCdMnfcRtvvaB", @"URL should be correct.");
}

- (void)testParsingAlbum1 {
	NSString *body = @"{"
	"  \"album_type\" : \"album\","
	"  \"artists\" : [ {"
	"    \"external_urls\" : {"
	"      \"spotify\" : \"https://open.spotify.com/artist/0TnOYISbd1XYRBk9myaseg\""
	"    },"
	"    \"href\" : \"https://api.spotify.com/v1/artists/0TnOYISbd1XYRBk9myaseg\","
	"    \"id\" : \"0TnOYISbd1XYRBk9myaseg\","
	"    \"name\" : \"Pitbull\","
	"    \"type\" : \"artist\","
	"    \"uri\" : \"spotify:artist:0TnOYISbd1XYRBk9myaseg\""
	"  } ],"
	"  \"copyrights\" : [ {"
	"    \"text\" : \"(P) 2012 RCA Records, a division of Sony Music Entertainment\","
	"    \"type\" : \"P\""
	"  } ],"
	"  \"external_ids\" : {"
	"    \"upc\" : \"886443671584\""
	"  },"
	"  \"external_urls\" : {"
	"    \"spotify\" : \"https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy\""
	"  },"
	"  \"genres\" : [ ],"
	"  \"href\" : \"https://api.spotify.com/v1/albums/4aawyAB9vmqN3uQ7FjRGTy\","
	"  \"id\" : \"4aawyAB9vmqN3uQ7FjRGTy\","
	"  \"images\" : [ {"
	"    \"height\" : 640,"
	"    \"url\" : \"https://i.scdn.co/image/9b535d1040f9512ba0c6554938251c01d5ddfbfc\","
	"    \"width\" : 640"
	"  }, {"
	"    \"height\" : 300,"
	"    \"url\" : \"https://i.scdn.co/image/0cf4a8587a811d7e1e5b52aeec4735552a1cf3c7\","
	"    \"width\" : 300"
	"  }, {"
	"    \"height\" : 64,"
	"    \"url\" : \"https://i.scdn.co/image/125521548f6a4bf771611c3cb42e00ab1dd753a4\","
	"    \"width\" : 64"
	"  } ],"
	"  \"name\" : \"Global Warming\","
	"  \"popularity\" : 72,"
	"  \"release_date\" : \"2012-11-13\","
	"  \"release_date_precision\" : \"day\","
	"  \"tracks\" : {"
	"    \"href\" : \"https://api.spotify.com/v1/albums/4aawyAB9vmqN3uQ7FjRGTy/tracks?offset=0&limit=50&market=ES\","
	"    \"items\" : [ {"
	"      \"artists\" : [ {"
	"        \"external_urls\" : {"
	"          \"spotify\" : \"https://open.spotify.com/artist/0TnOYISbd1XYRBk9myaseg\""
	"        },"
	"        \"href\" : \"https://api.spotify.com/v1/artists/0TnOYISbd1XYRBk9myaseg\","
	"        \"id\" : \"0TnOYISbd1XYRBk9myaseg\","
	"        \"name\" : \"Pitbull\","
	"        \"type\" : \"artist\","
	"        \"uri\" : \"spotify:artist:0TnOYISbd1XYRBk9myaseg\""
	"      }, {"
	"        \"external_urls\" : {"
	"          \"spotify\" : \"https://open.spotify.com/artist/7iJrDbKM5fEkGdm5kpjFzS\""
	"        },"
	"        \"href\" : \"https://api.spotify.com/v1/artists/7iJrDbKM5fEkGdm5kpjFzS\","
	"        \"id\" : \"7iJrDbKM5fEkGdm5kpjFzS\","
	"        \"name\" : \"Sensato\","
	"        \"type\" : \"artist\","
	"        \"uri\" : \"spotify:artist:7iJrDbKM5fEkGdm5kpjFzS\""
	"      } ],"
	"      \"disc_number\" : 1,"
	"      \"duration_ms\" : 85400,"
	"      \"explicit\" : true,"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"https://open.spotify.com/track/6OmhkSOpvYBokMKQxpIGx2\""
	"      },"
	"      \"href\" : \"https://api.spotify.com/v1/tracks/6OmhkSOpvYBokMKQxpIGx2\","
	"      \"id\" : \"6OmhkSOpvYBokMKQxpIGx2\","
	"      \"is_playable\" : true,"
	"      \"name\" : \"Global Warming\","
	"      \"preview_url\" : \"https://p.scdn.co/mp3-preview/e1b3966a0f33266ad819a17155c7c00244e7f752\","
	"      \"track_number\" : 1,"
	"      \"type\" : \"track\","
	"      \"uri\" : \"spotify:track:6OmhkSOpvYBokMKQxpIGx2\""
	"    }, {"
	"      \"artists\" : [ {"
	"        \"external_urls\" : {"
	"          \"spotify\" : \"https://open.spotify.com/artist/0TnOYISbd1XYRBk9myaseg\""
	"        },"
	"        \"href\" : \"https://api.spotify.com/v1/artists/0TnOYISbd1XYRBk9myaseg\","
	"        \"id\" : \"0TnOYISbd1XYRBk9myaseg\","
	"        \"name\" : \"Pitbull\","
	"        \"type\" : \"artist\","
	"        \"uri\" : \"spotify:artist:0TnOYISbd1XYRBk9myaseg\""
	"      }, {"
	"        \"external_urls\" : {"
	"          \"spotify\" : \"https://open.spotify.com/artist/7bXgB6jMjp9ATFy66eO08Z\""
	"        },"
	"        \"href\" : \"https://api.spotify.com/v1/artists/7bXgB6jMjp9ATFy66eO08Z\","
	"        \"id\" : \"7bXgB6jMjp9ATFy66eO08Z\","
	"        \"name\" : \"Chris Brown\","
	"        \"type\" : \"artist\","
	"        \"uri\" : \"spotify:artist:7bXgB6jMjp9ATFy66eO08Z\""
	"      } ],"
	"      \"disc_number\" : 1,"
	"      \"duration_ms\" : 309626,"
	"      \"explicit\" : false,"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"https://open.spotify.com/track/4TWgcICXXfGty8MHGWJ4Ne\""
	"      },"
	"      \"href\" : \"https://api.spotify.com/v1/tracks/4TWgcICXXfGty8MHGWJ4Ne\","
	"      \"id\" : \"4TWgcICXXfGty8MHGWJ4Ne\","
	"      \"is_playable\" : true,"
	"      \"name\" : \"International Love - Jump Smokers Extended Mix\","
	"      \"preview_url\" : \"https://p.scdn.co/mp3-preview/87779ee69b317c92027475288c5de7da286571ff\","
	"      \"track_number\" : 18,"
	"      \"type\" : \"track\","
	"      \"uri\" : \"spotify:track:4TWgcICXXfGty8MHGWJ4Ne\""
	"    } ],"
	"    \"limit\" : 50,"
	"    \"next\" : null,"
	"    \"offset\" : 0,"
	"    \"previous\" : null,"
	"    \"total\" : 18"
	"  },"
	"  \"type\" : \"album\","
	"  \"uri\" : \"spotify:album:4aawyAB9vmqN3uQ7FjRGTy\""
	"}";
	
	NSError *err = nil;
	SPTAlbum *album = [SPTAlbum albumFromData:[body dataUsingEncoding:NSUTF8StringEncoding] withResponse:nil error:&err];

	// Verify response
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertEqualObjects(album.name, @"Global Warming", @"Name should be set.");
	XCTAssertEqual(2, album.firstTrackPage.items.count, @"Tracks should have correctl length.");
	XCTAssertEqual(72, album.popularity, @"Popularity should be set.");
	XCTAssertEqual(18, album.firstTrackPage.totalListLength, @"Total number of tracks should be set.");
	XCTAssertEqual(SPTAlbumTypeAlbum, album.type, @"Should be an album");

	SPTPartialTrack *track0 = [album.firstTrackPage.items objectAtIndex:0];
	SPTPartialArtist *track0artist0 = [track0.artists objectAtIndex:0];
	XCTAssertEqualObjects(@"Pitbull", track0artist0.name, @"First track first artist should be Pitbull :/");
}

@end
