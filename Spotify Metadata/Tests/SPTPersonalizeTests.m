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
#import "SPTPersonalize.h"
#import "SPTArtist.h"
#import "SPTTrack.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTPersonalizeTests : XCTestCase<SPTRequestHandlerProtocol>

@end

@implementation SPTPersonalizeTests {
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

- (void)testCreateRequestForUsersTop1 {
	NSError *err = nil;
	NSURLRequest *req;

	req = [SPTPersonalize createRequestForUsersTopWithType:SPTPersonalizeTypeArtists
											   accessToken:nil
													 error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/me/top/artists?limit=20&offset=0&time_range=medium_term", @"URL should be correct.");
}

- (void)testCreateRequestForUsersTop2 {
	NSError *err = nil;
	NSURLRequest *req;

	req = [SPTPersonalize createRequestForUsersTopWithType:SPTPersonalizeTypeTracks
											   accessToken:nil
													 error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/me/top/tracks?limit=20&offset=0&time_range=medium_term", @"URL should be correct.");
}

- (void)testCreateRequestForUsersTop3 {
	NSError *err = nil;
	NSURLRequest *req;

	req = [SPTPersonalize createRequestForUsersTopWithType:SPTPersonalizeTypeArtists
													offset:0
											   accessToken:nil
												 timeRange:SPTPersonalizeTimeRangeMedium
													 error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/me/top/artists?limit=20&offset=0&time_range=medium_term", @"URL should be correct.");
}

- (void)testCreateRequestForUsersTop4 {
	NSError *err = nil;
	NSURLRequest *req;

	req = [SPTPersonalize createRequestForUsersTopWithType:SPTPersonalizeTypeArtists
													offset:999
											   accessToken:nil
												 timeRange:SPTPersonalizeTimeRangeLong
													 error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/me/top/artists?limit=20&offset=999&time_range=long_term", @"URL should be correct.");
}

- (void)testCreateRequestForUsersTop5 {
	NSError *err = nil;
	NSURLRequest *req;

	req = [SPTPersonalize createRequestForUsersTopWithType:SPTPersonalizeTypeTracks
													offset:-5
											   accessToken:nil
												 timeRange:SPTPersonalizeTimeRangeShort
													 error:&err];
	XCTAssertNil(err, @"Should not return an error.");
	XCTAssertNotNil(req, @"Should return a request.");
	XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.spotify.com/v1/me/top/tracks?limit=20&offset=-5&time_range=short_term", @"URL should be correct.");
}

@end
