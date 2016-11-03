//
//  SPTUserTests.m
//  Spotify iOS SDK
//
//  Created by Per-Olov Jernberg on 02/03/15.
//  Copyright (c) 2015 Spotify AB. All rights reserved.
//

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
