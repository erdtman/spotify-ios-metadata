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
#import "SPTSearch.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPLookupTests : XCTestCase

@end

@implementation SPLookupTests

- (void)setUp
{
	[super setUp];
	// Put setup code here; it will be run once, before the first test case.
	[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"api.spotify.com"];
}

- (void)tearDown
{
	// Put teardown code here; it will be run once, after the last test case.
	[super tearDown];
}

- (void)testPerformTrackSearchWithQuery
{
	[SPTSearch performSearchWithQuery:@"12345" queryType:SPTQueryTypeTrack accessToken:nil market:nil callback:^(NSError *error, SPTListPage *object) {

		XCTAssert(error == nil, @"Got an error trying to get search results");
		XCTAssert(object != nil, @"Was expecting an object, but got nil");
		XCTAssert(object.items.count == 20, @"Was expecting 20 items, but got %@", @(object.items.count));

		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

- (void)testPerformTrackSearchWithQueryAndNextPage
{
	[SPTSearch performSearchWithQuery:@"12345" queryType:SPTQueryTypeTrack accessToken:nil market:nil callback:^(NSError *error, SPTListPage *object) {

		XCTAssert(error == nil, @"Got an error trying to get search results");
		XCTAssert(object != nil, @"Was expecting an object, but got nil");
		XCTAssert(object.items.count == 20, @"Was expecting 20 items, but got %@", @(object.items.count));

		[object requestNextPageWithAccessToken:nil callback:^(NSError *nextError, SPTListPage *nextPage) {
			XCTAssertNil(nextError, @"Got an error trying to get second page of search results");
			XCTAssertNotNil(nextPage, @"Was expecting an object, but got nil");
			XCTAssert(nextPage.range.location == object.range.location + object.range.length, @"Second search page should immediately follow first page");

			[self notify:XCTAsyncTestCaseStatusSucceeded];
		}];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

- (void)testPerformTrackSearchWithQueryAndOffset
{
	[SPTSearch performSearchWithQuery:@"12345" queryType:SPTQueryTypeTrack accessToken:nil market:nil callback:^(NSError *error, SPTListPage *object) {
		[SPTSearch performSearchWithQuery:@"12345" queryType:SPTQueryTypeTrack offset:2 accessToken:nil callback:^(NSError *error, SPTListPage *offsetObject) {
			XCTAssert(error == nil, @"Got an error trying to get search results");
			XCTAssert(offsetObject != nil, @"Was expecting an object, but got nil");
			XCTAssert(object.items.count == 20, @"Was expecting 20 items, but got %@", @(object.items.count));

			// Compare two pages
			XCTAssertNotEqual(object.items, offsetObject.items, @"Two pages should be different, but are equal");

			[self notify:XCTAsyncTestCaseStatusSucceeded];
		}];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

-(void)testPerformAlbumSearchWithSpaces
{
	[SPTSearch performSearchWithQuery:@"Ben Folds Five" queryType:SPTQueryTypeAlbum accessToken:nil market:nil callback:^(NSError *error, SPTListPage *object) {

		XCTAssert(error == nil, @"Got an error trying to get search results");
		XCTAssert(object != nil, @"Was expecting an object, but got nil");
		XCTAssert([object totalListLength] > 5, @"Was expecting at least 5 items, but got %@", @([object totalListLength]));

		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

-(void)testPerformArtistSearchWithAccentedCharacters
{
	[SPTSearch performSearchWithQuery:@"Janelle Monáe" queryType:SPTQueryTypeArtist accessToken:nil market:nil callback:^(NSError *error, SPTListPage *object) {

		XCTAssert(error == nil, @"Got an error trying to get search results");
		XCTAssert(object != nil, @"Was expecting an object, but got nil");
		XCTAssert([object totalListLength] > 0, @"Was expecting at least 1 item");
		XCTAssertEqualObjects([[object.items objectAtIndex:0] name], @"Janelle Monáe", @"Was expecting to get 'Janelle Monáe' as first result, but got %@", [[object.items objectAtIndex:0] name]);

		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

-(void)testInternalMultigetFunction {
	NSMutableArray *inputs = [NSMutableArray array];
	[inputs addObject:@"a0"];
	[inputs addObject:@"b0"];
	[inputs addObject:@"c0"];
	[inputs addObject:@"d0"];
	[inputs addObject:@"e0"];

	[inputs addObject:@"a1"];
	[inputs addObject:@"b1"];
	[inputs addObject:@"c1"];
	[inputs addObject:@"d1"];
	[inputs addObject:@"e1"];
	
	[inputs addObject:@"a2"];
	[inputs addObject:@"b2"];
	[inputs addObject:@"c2"];
	[inputs addObject:@"d2"];
	[inputs addObject:@"e2"];
	
	[inputs addObject:@"a3"];
	[inputs addObject:@"b3"];
	
	NSLog(@"starting paging...");
	__block int pagecallcounter = 0 ;
	__block int totalinputs = 0;
	
	[SPTRequest performSequentialMultiget:inputs pager:^(NSArray *pageinputs, SPTRequestCallback callback) {
		NSLog(@"getting page of items: %@", pageinputs);
		pagecallcounter ++;
		XCTAssertTrue(pageinputs.count <= 5);
		totalinputs += pageinputs.count;
		callback(nil, pageinputs);
	} pagesize:5 callback:^(NSError *error, id object) {
		NSArray *result = (NSArray *)object;
		NSLog(@"got final callback, %@", result);
		XCTAssert(inputs.count == result.count);
		XCTAssert(pagecallcounter == 4);
		XCTAssert(inputs.count == totalinputs);

		XCTAssertEqualObjects([result objectAtIndex:0], @"a0");
		XCTAssertEqualObjects([result objectAtIndex:1], @"b0");
		XCTAssertEqualObjects([result objectAtIndex:2], @"c0");
		XCTAssertEqualObjects([result objectAtIndex:3], @"d0");
		XCTAssertEqualObjects([result objectAtIndex:4], @"e0");
		
		XCTAssertEqualObjects([result objectAtIndex:5], @"a1");
		XCTAssertEqualObjects([result objectAtIndex:6], @"b1");
		XCTAssertEqualObjects([result objectAtIndex:7], @"c1");
		XCTAssertEqualObjects([result objectAtIndex:8], @"d1");
		XCTAssertEqualObjects([result objectAtIndex:9], @"e1");
		
		XCTAssertEqualObjects([result objectAtIndex:10], @"a2");
		XCTAssertEqualObjects([result objectAtIndex:11], @"b2");
		XCTAssertEqualObjects([result objectAtIndex:12], @"c2");
		XCTAssertEqualObjects([result objectAtIndex:13], @"d2");
		XCTAssertEqualObjects([result objectAtIndex:14], @"e2");
		
		XCTAssertEqualObjects([result objectAtIndex:15], @"a3");
		XCTAssertEqualObjects([result objectAtIndex:16], @"b3");
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}


-(void)testInternalMultigetFunctionErrorHandling {
	NSMutableArray *inputs = [NSMutableArray array];
	[inputs addObject:@"a0"];
	[inputs addObject:@"b0"];
	[inputs addObject:@"c0"];
	[inputs addObject:@"d0"];
	[inputs addObject:@"e0"];
	
	[inputs addObject:@"a1"];
	[inputs addObject:@"b1"];
	[inputs addObject:@"c1"];
	[inputs addObject:@"d1"];
	[inputs addObject:@"e1"];
	
	[inputs addObject:@"a2"];
	[inputs addObject:@"b2"];
	[inputs addObject:@"c2"];
	[inputs addObject:@"d2"];
	[inputs addObject:@"e2"];
	
	[inputs addObject:@"a3"];
	[inputs addObject:@"b3"];
	
	NSLog(@"starting paging...");
	__block int pagecallcounter = 0 ;
	__block int totalinputs = 0;
	
	[SPTRequest performSequentialMultiget:inputs pager:^(NSArray *pageinputs, SPTRequestCallback callback) {
		NSLog(@"getting page of items: %@", pageinputs);
		XCTAssertTrue(pageinputs.count <= 5);
		totalinputs += pageinputs.count;
		if (pagecallcounter == 2) {
			callback([NSError errorWithDomain:@"domain123" code:123 userInfo:nil], nil);
		} else {
			callback(nil, pageinputs);
		}
		pagecallcounter ++;
	} pagesize:5 callback:^(NSError *error, id object) {
		XCTAssertEqualObjects(error.domain, @"domain123");
		XCTAssert(error.code == 123);
		
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1.0];
}


@end
