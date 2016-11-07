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
#import "SPTUser.h"

@interface NSURLRequest (ApplePrivate)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SPTUserTests : XCTestCase

@end

@implementation SPTUserTests

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

- (void)testUserShouldNotReturnNullStringDisplayName
{
	[SPTRequest queueMockResponse:@"{\n"
	 "  \"country\" : \"IT\","
	 "  \"display_name\" : null,"
	 "  \"email\" : \"xxxx@xxxx.com\","
	 "  \"external_urls\" : {"
	 "	  \"spotify\" : \"https://open.spotify.com/userxxxx\""
	 "  },"
	 "  \"followers\" : {"
	 "	  \"href\" : null,"
	 "	  \"total\" : 0"
	 "  },"
	 "  \"href\" : \"https://api.spotify.com/v1/users/xxxxx\","
	 "  \"id\" : \"streamtestmxm\","
	 "  \"images\" : [ ],"
	 "  \"product\" : \"premium\","
	 "  \"type\" : \"user\","
	 "  \"uri\" : \"spotify:user:xxxxxx\""
	 "}"];

	[SPTUser requestCurrentUserWithAccessToken:nil callback:^(NSError *error, SPTUser *object) {
		XCTAssertEqualObjects(nil, object.displayName);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];

	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10.0];
}

@end
