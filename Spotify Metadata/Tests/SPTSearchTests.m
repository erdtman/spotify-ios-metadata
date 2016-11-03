
#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"

#import "SPTRequest_Internal.h"
#import "SPTSearch.h"
#import "SPTPartialTrack.h"
#import "SPTPartialArtist.h"
#import "SPTPartialPlaylist.h"
#import "SPTUser.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTSearchTests : XCTestCase<SPTRequestHandlerProtocol>

@end

@implementation SPTSearchTests {
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


- (void)testCreateRequestForSearch1 {
	NSError *err = nil;
	NSURLRequest *req;
	
	req = [SPTSearch createRequestForSearchWithQuery:@"query 123" queryType:SPTQueryTypePlaylist accessToken:nil error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/search?limit=20&offset=0&q=query%20123&type=playlist", @"URL should be correct.");
}

- (void)testCreateRequestForSearch2 {
	NSError *err = nil;
	NSURLRequest *req;
		
	req = [SPTSearch createRequestForSearchWithQuery:@" Yello " queryType:SPTQueryTypeArtist offset:999 accessToken:@"tok" error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/search?limit=20&offset=999&q=%20Yello%20&type=artist", @"URL should be correct.");
}

- (void)testCreateRequestForSearch3 {
	NSError *err = nil;
	NSURLRequest *req;
	
	req = [SPTSearch createRequestForSearchWithQuery:@"query123" queryType:SPTQueryTypeTrack offset:-3 accessToken:@"tok" market:@"ES" error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/search?limit=20&market=ES&offset=-3&q=query123&type=track", @"URL should be correct.");
}


- (void)testConvenienceMethods1 {
	mockResponse = @"{"
	"  \"tracks\" : {"
	"    \"href\" : \"https://api.spotify.com/v1/search?query=Muse&offset=7&limit=1&type=track&market=US\","
	"    \"items\" : [ {"
	"      \"available_markets\" : [ \"AD\", \"AR\" ],"
	"      \"disc_number\" : 1,"
	"      \"duration_ms\" : 366213,"
	"      \"explicit\" : false,"
	"      \"external_ids\" : {"
	"        \"isrc\" : \"GBAHT0500600\""
	"      },"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"https://open.spotify.com/track/7ouMYWpwJ422jRcDASZB7P\""
	"      },"
	"      \"href\" : \"https://api.spotify.com/v1/tracks/7ouMYWpwJ422jRcDASZB7P\","
	"      \"id\" : \"7ouMYWpwJ422jRcDASZB7P\","
	"      \"name\" : \"Knights Of Cydonia\","
	"      \"popularity\" : 67,"
	"      \"preview_url\" : \"https://p.scdn.co/mp3-preview/2b6c3895a06c1d5e0638c88f8b035dff1d1d4831\","
	"      \"track_number\" : 11,"
	"      \"type\" : \"track\","
	"      \"uri\" : \"spotify:track:7ouMYWpwJ422jRcDASZB7P\""
	"    } ],"
	"    \"limit\" : 1,"
	"    \"next\" : \"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=track&market=US\","
	"    \"offset\" : 7,"
	"    \"previous\" : \"https://api.spotify.com/v1/search?query=Muse&offset=6&limit=1&type=track&market=US\","
	"    \"total\" : 9005"
	"  }"
	"}";

	[SPTSearch performSearchWithQuery:@"query 123"
							queryType:SPTQueryTypeTrack
						  accessToken:@"dummy"
							   market:@"SE"
							 callback:^(NSError *error, SPTListPage *list) {
		XCTAssertEqualObjects(lastRequest.URL.absoluteString, @"https://api.spotify.com/v1/search?limit=20&market=SE&offset=0&q=query%20123&type=track");
		SPTPartialTrack *track = (SPTPartialTrack *)[list.items objectAtIndex:0];
		XCTAssertEqualObjects(track.name, @"Knights Of Cydonia");
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:100.0];
}

/** Test that the next page call uses the api url returned in the first page */
- (void)testConvenienceMethods2 {

	mockResponse = @"{"
	"  \"tracks\" : {"
	"    \"href\" : \"https://api.spotify.com/v1/search?query=Muse&offset=7&limit=1&type=track&market=US\","
	"    \"items\" : [ {"
	"      \"href\" : \"https://api.spotify.com/v1/tracks/7ouMYWpwJ422jRcDASZB7P\","
	"      \"id\" : \"7ouMYWpwJ422jRcDASZB7P\","
	"      \"name\" : \"Knights Of Cydonia\","
	"      \"track_number\" : 11,"
	"      \"type\" : \"track\","
	"      \"uri\" : \"spotify:track:7ouMYWpwJ422jRcDASZB7P\""
	"    } ],"
	"    \"limit\" : 888,"
	"    \"next\" : \"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=track&market=US\","
	"    \"offset\" : 999,"
	"    \"total\" : 9005"
	"  }"
	"}";

	[SPTSearch performSearchWithQuery:@"query 123" queryType:SPTQueryTypeTrack accessToken:@"dummy" market:@"SE" callback:^(NSError *error, SPTListPage *page1) {
		XCTAssertEqualObjects(lastRequest.URL.absoluteString, @"https://api.spotify.com/v1/search?limit=20&market=SE&offset=0&q=query%20123&type=track");
		XCTAssertEqualObjects(page1.nextPageURL.absoluteString, @"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=track&market=US");
	
		mockResponse = @"{"
		"  \"tracks\" : {"
		"    \"href\" : \"https://api.spotify.com/v1/search?query=Muse&offset=7&limit=1&type=track&market=US\","
		"    \"items\" : [ {"
		"      \"explicit\" : false,"
		"      \"href\" : \"https://api.spotify.com/v1/tracks/7ouMYWpwJ422jRcDASZB7P\","
		"      \"id\" : \"7ouMYWpwJ422jRcDASZB7P\","
		"      \"name\" : \"Knights Of Cydonia\","
		"      \"track_number\" : 11,"
		"      \"type\" : \"track\","
		"      \"uri\" : \"spotify:track:7ouMYWpwJ422jRcDASZB7P\""
		"    } ],"
		"    \"limit\" : 1,"
		"    \"next\" : \"https://api.spotify.com/v1/search?query=Muse&offset=9&limit=1&type=track&market=US\","
		"    \"offset\" : 7,"
		"    \"previous\" : \"https://api.spotify.com/v1/search?query=Muse&offset=6&limit=1&type=track&market=US\","
		"    \"total\" : 9005"
		"  }"
		"}";

		[page1 requestNextPageWithAccessToken:@"dummy2" callback:^(NSError *error, SPTListPage *page2) {
			XCTAssertEqualObjects(lastRequest.URL.absoluteString, @"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=track&market=US");
			XCTAssertEqualObjects(page2.nextPageURL.absoluteString, @"https://api.spotify.com/v1/search?query=Muse&offset=9&limit=1&type=track&market=US");
			
			[self notify:XCTAsyncTestCaseStatusSucceeded];
		}];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:100.0];
}

- (void)testDecodeTrackSearchResults
{
	NSString *body = @"{"
	"  \"tracks\" : {"
	"    \"href\" : \"https://api.spotify.com/v1/search?query=Muse&offset=7&limit=1&type=track&market=US\","
	"    \"items\" : [ {"
	"      \"album\" : {"
	"        \"album_type\" : \"album\","
	"        \"available_markets\" : [ \"AD\", \"AR\", \"AT\", \"AU\" ],"
	"        \"external_urls\" : {"
	"          \"spotify\" : \"https://open.spotify.com/album/0lw68yx3MhKflWFqCsGkIs\""
	"        },"
	"        \"href\" : \"https://api.spotify.com/v1/albums/0lw68yx3MhKflWFqCsGkIs\","
	"        \"id\" : \"0lw68yx3MhKflWFqCsGkIs\","
	"        \"images\" : [ {"
	"          \"height\" : 640,"
	"          \"url\" : \"https://i.scdn.co/image/cc938203606c1673a4e32334967f3621ed6769fe\","
	"          \"width\" : 640"
	"        }, {"
	"          \"height\" : 300,"
	"          \"url\" : \"https://i.scdn.co/image/acf6bd01fe17c53a7ef0b92fe52d3590d57df13e\","
	"          \"width\" : 300"
	"        }, {"
	"          \"height\" : 64,"
	"          \"url\" : \"https://i.scdn.co/image/6c751d61a730ab14dca55b1c7d3ce1f7f838aa23\","
	"          \"width\" : 64"
	"        } ],"
	"        \"name\" : \"Black Holes And Revelations\","
	"        \"type\" : \"album\","
	"        \"uri\" : \"spotify:album:0lw68yx3MhKflWFqCsGkIs\""
	"      },"
	"      \"artists\" : [ {"
	"        \"external_urls\" : {"
	"          \"spotify\" : \"https://open.spotify.com/artist/12Chz98pHFMPJEknJQMWvI\""
	"        },"
	"        \"href\" : \"https://api.spotify.com/v1/artists/12Chz98pHFMPJEknJQMWvI\","
	"        \"id\" : \"12Chz98pHFMPJEknJQMWvI\","
	"        \"name\" : \"Muse\","
	"        \"type\" : \"artist\","
	"        \"uri\" : \"spotify:artist:12Chz98pHFMPJEknJQMWvI\""
	"      } ],"
	"      \"available_markets\" : [ \"AD\", \"AR\" ],"
	"      \"disc_number\" : 1,"
	"      \"duration_ms\" : 366213,"
	"      \"explicit\" : false,"
	"      \"external_ids\" : {"
	"        \"isrc\" : \"GBAHT0500600\""
	"      },"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"https://open.spotify.com/track/7ouMYWpwJ422jRcDASZB7P\""
	"      },"
	"      \"href\" : \"https://api.spotify.com/v1/tracks/7ouMYWpwJ422jRcDASZB7P\","
	"      \"id\" : \"7ouMYWpwJ422jRcDASZB7P\","
	"      \"name\" : \"Knights Of Cydonia\","
	"      \"popularity\" : 67,"
	"      \"preview_url\" : \"https://p.scdn.co/mp3-preview/2b6c3895a06c1d5e0638c88f8b035dff1d1d4831\","
	"      \"track_number\" : 11,"
	"      \"type\" : \"track\","
	"      \"uri\" : \"spotify:track:7ouMYWpwJ422jRcDASZB7P\""
	"    } ],"
	"    \"limit\" : 1,"
	"    \"next\" : \"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=track&market=US\","
	"    \"offset\" : 7,"
	"    \"previous\" : \"https://api.spotify.com/v1/search?query=Muse&offset=6&limit=1&type=track&market=US\","
	"    \"total\" : 9005"
	"  }"
	"}";
	
	NSError *parseerror = nil;
	SPTListPage *page = [SPTSearch searchResultsFromData:[body dataUsingEncoding:NSUTF8StringEncoding]  withResponse:nil queryType:SPTQueryTypeTrack error:&parseerror];

	// Verify response
	XCTAssertNil(parseerror, @"Should not return an error.");
	XCTAssertEqualObjects(@"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=track&market=US",
						  [page.nextPageURL absoluteString], @"Next page should be set.");
	XCTAssertEqualObjects(@"https://api.spotify.com/v1/search?query=Muse&offset=6&limit=1&type=track&market=US",
						  [page.previousPageURL absoluteString], @"Previous page should be set.");
	XCTAssertEqual(1, page.range.length, @"Limit should be set.");
	XCTAssertEqual(7, page.range.location, @"Offset should be set.");
	XCTAssertEqual(9005, page.totalListLength, @"Total should be set.");
	XCTAssertEqual(1, page.items.count, @"Only one item should be returned.");

	// Verify track
	SPTPartialTrack *track = (SPTPartialTrack *)[[page items] objectAtIndex:0];
	XCTAssertNotNil(track, @"First track should not be null");
	XCTAssertEqualObjects(@"Knights Of Cydonia", track.name, @"Track name should be set.");
	
	// Verify track artist
	SPTPartialAlbum *album = track.album;
	XCTAssertNotNil(album, @"First track album should not be null");
	XCTAssertEqualObjects(@"Black Holes And Revelations", album.name, @"Album name should be set.");
	
	// Verify track artist
	SPTPartialArtist *artist = (SPTPartialArtist *)[[track artists] objectAtIndex:0];
	XCTAssertNotNil(artist, @"First track artist should not be null");
	XCTAssertEqualObjects(@"Muse", artist.name, @"Artist name should be set.");
}



- (void)testDecodeArtistSearchResults
{
	NSString *body = @"{"
	"  \"artists\" : {"
	"    \"href\" : \"https://api.spotify.com/v1/search?query=Muse&offset=7&limit=1&type=artist&market=US\","
	"    \"items\" : [ {"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"https://open.spotify.com/artist/1LZX9fzyLrGXkwn3KYX6YW\""
	"      },"
	"      \"followers\" : {"
	"        \"href\" : null,"
	"        \"total\" : 12"
	"      },"
	"      \"genres\" : [ ],"
	"      \"href\" : \"https://api.spotify.com/v1/artists/1LZX9fzyLrGXkwn3KYX6YW\","
	"      \"id\" : \"1LZX9fzyLrGXkwn3KYX6YW\","
	"      \"images\" : [ {"
	"        \"height\" : 640,"
	"        \"url\" : \"https://i.scdn.co/image/c56a9b294bc6942bd789c18d2983fb9bbb565af4\","
	"        \"width\" : 640"
	"      }, {"
	"        \"height\" : 300,"
	"        \"url\" : \"https://i.scdn.co/image/28317d20143e7302908607d672254448d73c56ee\","
	"        \"width\" : 300"
	"      }, {"
	"        \"height\" : 64,"
	"        \"url\" : \"https://i.scdn.co/image/cafdfe47396a085d128aeb12d7c010ba64c7f981\","
	"        \"width\" : 64"
	"      } ],"
	"      \"name\" : \"Terrence Muse\","
	"      \"popularity\" : 7,"
	"      \"type\" : \"artist\","
	"      \"uri\" : \"spotify:artist:1LZX9fzyLrGXkwn3KYX6YW\""
	"    } ],"
	"    \"limit\" : 1,"
	"    \"next\" : \"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=artist&market=US\","
	"    \"offset\" : 7,"
	"    \"previous\" : \"https://api.spotify.com/v1/search?query=Muse&offset=6&limit=1&type=artist&market=US\","
	"    \"total\" : 97"
	"  }"
	"}";
	
	NSError *parseerror = nil;
	SPTListPage *page = [SPTSearch searchResultsFromData:[body dataUsingEncoding:NSUTF8StringEncoding]  withResponse:nil queryType:SPTQueryTypeArtist error:&parseerror];
	
	// Verify response
	XCTAssertNil(parseerror, @"Should not return an error.");
	XCTAssertEqualObjects(@"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=artist&market=US",
						  [page.nextPageURL absoluteString], @"Next page should be set.");
	XCTAssertEqualObjects(@"https://api.spotify.com/v1/search?query=Muse&offset=6&limit=1&type=artist&market=US",
						  [page.previousPageURL absoluteString], @"Previous page should be set.");
	XCTAssertEqual(1, page.range.length, @"Limit should be set.");
	XCTAssertEqual(7, page.range.location, @"Offset should be set.");
	XCTAssertEqual(97, page.totalListLength, @"Total should be set.");
	XCTAssertEqual(1, page.items.count, @"Only one item should be returned.");
	
	// Verify artist
	SPTPartialArtist *artist = (SPTPartialArtist *)[page.items objectAtIndex:0];
	XCTAssertNotNil(artist, @"First track artist should not be null");
	XCTAssertEqualObjects(@"Terrence Muse", artist.name, @"Artist name should be set.");
}



- (void)testDecodeAlbumSearchResults
{
	NSString *body = @"{"
	"  \"albums\" : {"
	"    \"href\" : \"https://api.spotify.com/v1/search?query=Muse&offset=7&limit=1&type=album&market=US\","
	"    \"items\" : [ {"
	"      \"album_type\" : \"album\","
	"      \"available_markets\" : [ \"AD\", \"AR\" ],"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"https://open.spotify.com/album/2m7L60M210ABzrY9GLyBPZ\""
	"      },"
	"      \"href\" : \"https://api.spotify.com/v1/albums/2m7L60M210ABzrY9GLyBPZ\","
	"      \"id\" : \"2m7L60M210ABzrY9GLyBPZ\","
	"      \"name\" : \"Live At Rome Olympic Stadium\","
	"      \"type\" : \"album\","
	"      \"uri\" : \"spotify:album:2m7L60M210ABzrY9GLyBPZ\""
	"    } ],"
	"    \"limit\" : 1,"
	"    \"next\" : \"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=album&market=US\","
	"    \"offset\" : 7,"
	"    \"previous\" : \"https://api.spotify.com/v1/search?query=Muse&offset=6&limit=1&type=album&market=US\","
	"    \"total\" : 687"
	"  }"
	"}";
	
	NSError *parseerror = nil;
	SPTListPage *page = [SPTSearch searchResultsFromData:[body dataUsingEncoding:NSUTF8StringEncoding]  withResponse:nil queryType:SPTQueryTypeAlbum error:&parseerror];
	
	// Verify response
	XCTAssertNil(parseerror, @"Should not return an error.");
	XCTAssertEqualObjects(@"https://api.spotify.com/v1/search?query=Muse&offset=8&limit=1&type=album&market=US",
						  [page.nextPageURL absoluteString], @"Next page should be set.");
	XCTAssertEqualObjects(@"https://api.spotify.com/v1/search?query=Muse&offset=6&limit=1&type=album&market=US",
						  [page.previousPageURL absoluteString], @"Previous page should be set.");
	XCTAssertEqual(1, page.range.length, @"Limit should be set.");
	XCTAssertEqual(7, page.range.location, @"Offset should be set.");
	XCTAssertEqual(687, page.totalListLength, @"Total should be set.");
	XCTAssertEqual(1, page.items.count, @"Only one item should be returned.");
	
	// Verify album
	SPTPartialAlbum *album = (SPTPartialAlbum *)[page.items objectAtIndex:0];
	XCTAssertNotNil(album, @"First album should not be null");
	XCTAssertEqualObjects(@"Live At Rome Olympic Stadium", album.name, @"Album name should be set.");
}



- (void)testDecodePlaylistSearchResults
{
	NSString *body = @"{"
	"  \"playlists\" : {"
	"    \"href\" : \"https://api.spotify.com/v1/search?query=Muse&offset=0&limit=1&type=playlist&market=US\","
	"    \"items\" : [ {"
	"      \"collaborative\" : false,"
	"      \"external_urls\" : {"
	"        \"spotify\" : \"http://open.spotify.com/user/1116540354/playlist/2fHjfy1CMbh2ZcMPjKFHC8\""
	"      },"
	"      \"href\" : \"https://api.spotify.com/v1/users/1116540354/playlists/2fHjfy1CMbh2ZcMPjKFHC8\","
	"      \"id\" : \"2fHjfy1CMbh2ZcMPjKFHC8\","
	"      \"name\" : \"MUSE!!!\","
	"      \"owner\" : {"
	"        \"external_urls\" : {"
	"          \"spotify\" : \"http://open.spotify.com/user/1116540354\""
	"        },"
	"        \"href\" : \"https://api.spotify.com/v1/users/1116540354\","
	"        \"id\" : \"1116540354\","
	"        \"type\" : \"user\","
	"        \"uri\" : \"spotify:user:1116540354\""
	"      },"
	"      \"public\" : null,"
	"      \"tracks\" : {"
	"        \"href\" : \"https://api.spotify.com/v1/users/1116540354/playlists/2fHjfy1CMbh2ZcMPjKFHC8/tracks\","
	"        \"total\" : 126"
	"      },"
	"      \"type\" : \"playlist\","
	"      \"uri\" : \"spotify:user:1116540354:playlist:2fHjfy1CMbh2ZcMPjKFHC8\""
	"    } ],"
	"    \"limit\" : 1,"
	"    \"next\" : \"https://api.spotify.com/v1/search?query=Muse&offset=1&limit=1&type=playlist&market=US\","
	"    \"offset\" : 0,"
	"    \"previous\" : null,"
	"    \"total\" : 782"
	"  }"
	"}";
	
	NSError *parseerror = nil;
	SPTListPage *page = [SPTSearch searchResultsFromData:[body dataUsingEncoding:NSUTF8StringEncoding]  withResponse:nil queryType:SPTQueryTypePlaylist error:&parseerror];
	
	// Verify response
	XCTAssertNil(parseerror, @"Should not return an error.");
	XCTAssertEqualObjects(@"https://api.spotify.com/v1/search?query=Muse&offset=1&limit=1&type=playlist&market=US",
						  [page.nextPageURL absoluteString], @"Next page should be set.");
	XCTAssertNil(page.previousPageURL, @"Previous page should be nil.");
	XCTAssertEqual(1, page.range.length, @"Limit should be set.");
	XCTAssertEqual(0, page.range.location, @"Offset should be set.");
	XCTAssertEqual(782, page.totalListLength, @"Total should be set.");
	XCTAssertEqual(1, page.items.count, @"Only one item should be returned.");
	
	// Verify playlist
	SPTPartialPlaylist *playlist = (SPTPartialPlaylist *)[page.items objectAtIndex:0];
	XCTAssertNotNil(playlist, @"First playlist should not be null");
	XCTAssertEqualObjects(@"MUSE!!!", playlist.name, @"Playlist name should be set.");
	XCTAssertEqualObjects(@"spotify:user:1116540354:playlist:2fHjfy1CMbh2ZcMPjKFHC8", [playlist.uri absoluteString], @"Playlist uri should be set.");
	XCTAssertEqual(126, playlist.trackCount, @"Playlist trackcount should be set.");
	XCTAssertEqualObjects(@"spotify:user:1116540354", [playlist.owner.uri absoluteString], @"Playlist trackcount should be set.");
}

@end
