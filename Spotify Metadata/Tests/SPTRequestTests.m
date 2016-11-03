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

#import "SPTRequest_Internal.h"
#import "SPTSearch.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTRequestTests : XCTestCase

@end

@implementation SPTRequestTests

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

- (void)testSearch
{
	[SPTSearch performSearchWithQuery:@"abba" queryType:SPTQueryTypeArtist accessToken:nil market:@"US" callback:^(NSError *error, SPTListPage *object) {
		XCTAssert(error == nil, @"Got an error trying to create object");
		XCTAssert(object != nil, @"Expected an object but got nil");
		XCTAssert([object.items count], @"Expected an a non empty list");
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

@end
