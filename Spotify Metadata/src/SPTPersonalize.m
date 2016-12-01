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

#import "SPTPersonalize.h"
#import "SPTRequest.h"
#import "SPTListPage.h"

@implementation SPTPersonalize

+(NSString *)typeNameFromPersonalizeType:(SPTPersonalizeType)type {
	if (type == SPTPersonalizeTypeArtists) {
		return @"artists";
	}
	if (type == SPTPersonalizeTypeTracks) {
		return @"tracks";
	}
	return @"";
};

+(NSString *)timeRangeNameFromTimeRange:(SPTPersonalizeTimeRange)timeRange {
	if (timeRange == SPTPersonalizeTimeRangeShort) {
		return @"short_term";
	}
	if (timeRange == SPTPersonalizeTimeRangeMedium) {
		return @"medium_term";
	}
	if (timeRange == SPTPersonalizeTimeRangeLong) {
		return @"long_term";
	}
	return @"";
};

+(SPTListPage *)userTopResultsFromDecodedJSON:(id)decodedObject
									queryType:(SPTPersonalizeType)type
										error:(NSError **)error {

	return [SPTListPage listPageFromDecodedJSON:decodedObject
					   expectingPartialChildren:NO
								  rootObjectKey:nil
										  error:error];
}

+(SPTListPage *)userTopResultsFromData:(NSData *)data
						  withResponse:(NSURLResponse *)response
							 queryType:(SPTPersonalizeType)type
								 error:(NSError **)error {

	NSError *err = nil;
	if (data == nil) {
		*error = [NSError errorWithDomain:@"com.spotify.ios-sdk" code:104 userInfo:nil];
		return nil;
	}
	id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
	if (err != nil) {
		*error = err;
		return nil;
	}
	return [self userTopResultsFromDecodedJSON:json queryType:type error:error];
}


+(void)requestUsersTopWithType:(SPTPersonalizeType)type
						offset:(NSInteger)offset
				   accessToken:(NSString *)accessToken
					 timeRange:(SPTPersonalizeTimeRange)timeRange
					  callback:(SPTRequestCallback)block {

	NSError *reqerr = nil;

	NSURLRequest *req = [self createRequestForUsersTopWithType:type
														offset:offset
												   accessToken:accessToken
													 timeRange:timeRange
														 error:&reqerr];

	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}

	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {

		NSError *resperr = nil;
		SPTListPage *page = [self userTopResultsFromData:data
											withResponse:response
											   queryType:type
												   error:&resperr];
		if (resperr != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(resperr, nil); });
			return;
		}

		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, page); });
	}];
}


+(void)requestUsersTopWithType:(SPTPersonalizeType)type
				   accessToken:(NSString *)accessToken
					  callback:(SPTRequestCallback)block {

	[self requestUsersTopWithType:type
						   offset:0
					  accessToken:accessToken
						timeRange:SPTPersonalizeTimeRangeMedium
						 callback:block];
}

+(NSURLRequest*)createRequestForUsersTopWithType:(SPTPersonalizeType)type
									 accessToken:(NSString *)accessToken
										   error:(NSError**)error {
	return [self createRequestForUsersTopWithType:type
										   offset:0
									  accessToken:accessToken
										timeRange:SPTPersonalizeTimeRangeMedium
											error:error];

}

+(NSURLRequest*)createRequestForUsersTopWithType:(SPTPersonalizeType)type
										  offset:(NSInteger)offset
									 accessToken:(NSString *)accessToken
									   timeRange:(SPTPersonalizeTimeRange)timeRange
										   error:(NSError**)error {
	NSString *personalizeType = [self typeNameFromPersonalizeType:type];
	NSURL *queryUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/me/top/%@", personalizeType]];
	NSMutableDictionary *values = [NSMutableDictionary dictionary];

	[values setValue:@(20) forKey:@"limit"];
	[values setValue:@(offset) forKey:@"offset"];
	[values setValue:[self timeRangeNameFromTimeRange:timeRange] forKey:@"time_range"];

	return [SPTRequest createRequestForURL:queryUrl
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

@end
