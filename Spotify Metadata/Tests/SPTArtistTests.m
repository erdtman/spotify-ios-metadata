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
#import "SPTArtist.h"
#import "SPTImage.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTArtistTests : XCTestCase

@end

@implementation SPTArtistTests

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

- (void)testLoadArtist
{
	[SPTArtist artistWithURI:[NSURL URLWithString:@"spotify:artist:4DToQR3aKrHQSSRzSz8Nzt"] accessToken:nil callback:^(NSError *error, SPTArtist *object) {
		XCTAssert(error == nil, @"Got error when loading Artist: %@", error);
		XCTAssert(object != nil, @"Expected an object but got nil");
		XCTAssert([object isKindOfClass:[SPTArtist class]], @"Expected class SPTArtist, but got %@", NSStringFromClass([object class]));
		XCTAssert([object.name isEqualToString:@"The Hives"], @"Expected name to be \"The Hives\" but got %@", object.name);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

- (void)testArtistProperties
{
	[SPTArtist artistWithURI:[NSURL URLWithString:@"spotify:artist:4tOVIRjlWWfR1RrAxyRqTE"] accessToken:nil callback:^(NSError *error, SPTArtist *artist) {
		XCTAssertEqualObjects([artist.uri absoluteString], @"spotify:artist:4tOVIRjlWWfR1RrAxyRqTE", @"Artist URI should be spotify:artist:4tOVIRjlWWfR1RrAxyRqTE (got %@)", artist.uri);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

- (void) testArtistRelatedArtists
{
	[SPTArtist artistWithURI:[NSURL URLWithString:@"spotify:artist:4tOVIRjlWWfR1RrAxyRqTE"] accessToken:nil callback:^(NSError *error, SPTArtist *artist) {
		[artist requestRelatedArtistsWithAccessToken:nil callback:^(NSError *error, NSArray *artists) {
			XCTAssertTrue([artists count] > 0);
			XCTAssert([[artists objectAtIndex:0] isKindOfClass:[SPTArtist class]], @"Expected class SPTArtist, but got %@", NSStringFromClass([[artists objectAtIndex:0] class]));
			[self notify:XCTAsyncTestCaseStatusSucceeded];
		}];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

- (void)testArtistMultiget {
	NSMutableArray *trackUris = [NSMutableArray array];
	[trackUris addObject:[NSURL URLWithString:@"spotify:artist:3Fobin2AT6OcrkLNsACzt4"]];
	[trackUris addObject:[NSURL URLWithString:@"spotify:artist:10yA9Y6h5wbDaX5XuZuA9X"]];
	[SPTArtist artistsWithURIs:trackUris accessToken:nil callback:^(NSError *error, id object) {
		NSArray *array = (NSArray *)object;
		
		SPTAlbum *artist0 = [array objectAtIndex:0];
		XCTAssertEqualObjects(artist0.name, @"Lazerhawk");
		
		SPTAlbum *artist1 = [array objectAtIndex:1];
		XCTAssertEqualObjects(artist1.name, @"Futurecop!");
		
		XCTAssertTrue(array.count == 2);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1000.0];
}

- (void) testArtistParser {
	NSString *body = @"{"
	"  \"external_urls\" : {"
	"    \"spotify\" : \"https://open.spotify.com/artist/0TnOYISbd1XYRBk9myaseg\""
	"  },"
	"  \"followers\" : {"
	"    \"href\" : null,"
	"    \"total\" : 2476505"
	"  },"
	"  \"genres\" : [ \"A\", \"B\", \"Poop\" ],"
	"  \"href\" : \"https://api.spotify.com/v1/artists/0TnOYISbd1XYRBk9myaseg\","
	"  \"id\" : \"0TnOYISbd1XYRBk9myaseg\","
	"  \"images\" : [ {"
	"    \"height\" : 563,"
	"    \"url\" : \"https://i.scdn.co/image/5f85e5201ae4c5dd50f60ee1feb4e1064683a90a\","
	"    \"width\" : 1000"
	"  }, {"
	"    \"height\" : 360,"
	"    \"url\" : \"https://i.scdn.co/image/9fd04c1995a00a83c2bee8f1b61cd1985fef1c79\","
	"    \"width\" : 640"
	"  }, {"
	"    \"height\" : 113,"
	"    \"url\" : \"https://i.scdn.co/image/4047ef29f1bd3f01ccad63284d7d7e6932bbcf54\","
	"    \"width\" : 200"
	"  }, {"
	"    \"height\" : 36,"
	"    \"url\" : \"https://i.scdn.co/image/776e79508e0e234aa63d9250ebbf1d6556839ef5\","
	"    \"width\" : 64"
	"  } ],"
	"  \"name\" : \"Pitbull\","
	"  \"popularity\" : 94,"
	"  \"type\" : \"artist\","
	"  \"uri\" : \"spotify:artist:0TnOYISbd1XYRBk9myaseg\""
	"}";
	
	NSError *err = nil;
	SPTArtist *artist = [SPTArtist artistFromData:[body dataUsingEncoding:NSUTF8StringEncoding] withResponse:nil error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(artist);
	XCTAssertEqualObjects(artist.name, @"Pitbull");
	XCTAssertEqualObjects(artist.identifier, @"0TnOYISbd1XYRBk9myaseg");
	XCTAssertEqual(artist.followerCount, 2476505);
	XCTAssertEqual(artist.popularity, 94);
	XCTAssertEqual(artist.genres.count, 3);
	XCTAssertTrue([artist.genres containsObject:@"A"]);
	XCTAssertTrue([artist.genres containsObject:@"B"]);
	XCTAssertTrue([artist.genres containsObject:@"Poop"]);
	XCTAssertEqual(artist.images.count, 4);

	XCTAssertEqualObjects(artist.largestImage.imageURL, [NSURL URLWithString:@"https://i.scdn.co/image/5f85e5201ae4c5dd50f60ee1feb4e1064683a90a"]);
	XCTAssertEqual(artist.largestImage.size.width, 1000);
	XCTAssertEqual(artist.largestImage.size.height, 563);
}

- (void) testMultiArtistParser {
	NSString *body = @"{"
	"  \"artists\" : [ {"
	"    \"external_urls\" : {"
	"      \"spotify\" : \"https://open.spotify.com/artist/2CIMQHirSU0MQqyYHq0eOx\""
	"    },"
	"    \"followers\" : {"
	"      \"href\" : null,"
	"      \"total\" : null"
	"    },"
	"    \"genres\" : [ \"edm\", \"electro house\", \"house\", \"progressive house\" ],"
	"    \"href\" : \"https://api.spotify.com/v1/artists/2CIMQHirSU0MQqyYHq0eOx\","
	"    \"id\" : \"2CIMQHirSU0MQqyYHq0eOx\","
	"    \"name\" : \"deadmau5\","
	"    \"popularity\" : 78,"
	"    \"type\" : \"artist\","
	"    \"uri\" : \"spotify:artist:2CIMQHirSU0MQqyYHq0eOx\""
	"  }, {"
	"    \"external_urls\" : {"
	"      \"spotify\" : \"https://open.spotify.com/artist/57dN52uHvrHOxijzpIgu3E\""
	"    },"
	"    \"followers\" : {"
	"      \"href\" : null,"
	"      \"total\" : null"
	"    },"
	"    \"genres\" : [ ],"
	"    \"href\" : \"https://api.spotify.com/v1/artists/57dN52uHvrHOxijzpIgu3E\","
	"    \"id\" : \"57dN52uHvrHOxijzpIgu3E\","
	"    \"name\" : \"Ratatat\","
	"    \"popularity\" : 76,"
	"    \"type\" : \"artist\","
	"    \"uri\" : \"spotify:artist:57dN52uHvrHOxijzpIgu3E\""
	"  }, {"
	"    \"external_urls\" : {"
	"      \"spotify\" : \"https://open.spotify.com/artist/1vCWHaC5f2uS3yhpwWbIA6\""
	"    },"
	"    \"followers\" : {"
	"      \"href\" : null,"
	"      \"total\" : null"
	"    },"
	"    \"genres\" : [ \"big room\", \"edm\", \"electro house\", \"house\", \"progressive electro house\" ],"
	"    \"href\" : \"https://api.spotify.com/v1/artists/1vCWHaC5f2uS3yhpwWbIA6\","
	"    \"id\" : \"1vCWHaC5f2uS3yhpwWbIA6\","
	"    \"name\" : \"Avicii\","
	"    \"popularity\" : 91,"
	"    \"type\" : \"artist\","
	"    \"uri\" : \"spotify:artist:1vCWHaC5f2uS3yhpwWbIA6\""
	"  } ]"
	"}";
	
	NSError *err = nil;
	NSArray *artists = [SPTArtist artistsFromData:[body dataUsingEncoding:NSUTF8StringEncoding] withResponse:nil error:&err];
	XCTAssertNil(err);
	XCTAssertNotNil(artists);
	XCTAssertEqual(artists.count, 3);
	
	SPTArtist *artist0 = [artists objectAtIndex:0];
	XCTAssertEqualObjects(artist0.name, @"deadmau5");

	SPTArtist *artist1 = [artists objectAtIndex:1];
	XCTAssertEqualObjects(artist1.name, @"Ratatat");

	SPTArtist *artist2 = [artists objectAtIndex:2];
	XCTAssertEqualObjects(artist2.name, @"Avicii");
}

@end
