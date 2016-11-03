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

#import "SPTBrowse.h"
#import "SPTRequest.h"
#import "SPTRequest_Internal.h"
#import "SPTListPage.h"
#import "SPTListPage_Internal.h"
#import "SPTFeaturedPlaylistList.h"
#import "SPTFeaturedPlaylistList_internal.h"

static NSString * const SPTBrowseFeaturedPlaylistsAPIURL = @"https://api.spotify.com/v1/browse/featured-playlists";
static NSString * const SPTBrowseNewReleasesAPIURL = @"https://api.spotify.com/v1/browse/new-releases";

@implementation SPTBrowse : NSObject





///----------------------------
/// @name API Request Factories
///----------------------------


/** Get a list of featured playlists */
+ (NSURLRequest *)createRequestForFeaturedPlaylistsInCountry:(NSString *)country
													   limit:(NSInteger)limit
													  offset:(NSInteger)offset
													  locale:(NSString *)locale
												   timestamp:(NSDate*)timestamp
												 accessToken:(NSString *)accessToken
													   error:(NSError **)error {
	
	NSURL *searchUrl = [NSURL URLWithString:SPTBrowseFeaturedPlaylistsAPIURL];
	NSError *err = nil;
	NSDictionary *values = [NSMutableDictionary dictionary];
	
	if (country != nil) {
		[values setValue:country forKey:@"country"];
	}
	if (locale != nil) {
		[values setValue:locale forKey:@"locale"];
	}
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
	if (timestamp != nil) {
		[values setValue:[formatter stringFromDate:timestamp] forKey:@"timestamp"];
	} else {
		[values setValue:[formatter stringFromDate:[NSDate date]] forKey:@"timestamp"];
	}
	
	[values setValue:@(limit) forKey:@"limit"];
	[values setValue:@(offset) forKey:@"offset"];
	
	return [SPTRequest createRequestForURL:searchUrl
						   withAccessToken:accessToken
								httpMethod:nil
									values:values
									 error:&err];
}


/** Get a list of new releases. */
+ (NSURLRequest *)createRequestForNewReleasesInCountry:(NSString *)country
												 limit:(NSInteger)limit
												offset:(NSInteger)offset
										   accessToken:(NSString *)accessToken
												 error:(NSError **)error {
	NSURL *searchUrl = [NSURL URLWithString:SPTBrowseNewReleasesAPIURL];
	NSDictionary *values = [NSMutableDictionary dictionary];
	
	if (country != nil) {
		[values setValue:country forKey:@"country"];
	}
	[values setValue:@(limit) forKey:@"limit"];
	[values setValue:@(offset) forKey:@"offset"];
	
	return [SPTRequest createRequestForURL:searchUrl
						   withAccessToken:accessToken
								httpMethod:nil
									values:values
									 error:error];
}








///---------------------------
/// @name API Response Parsers
///---------------------------

+ (SPTListPage *)newReleasesFromData:(NSData *)data
						withResponse:(NSURLResponse *)response
							   error:(NSError **)error {
	if (data == nil) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"Input is nil."];
		}
		return nil;
	}
	
	NSError *error2 = nil;
	id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error2];
	if (error2 != nil) {
		if (error != nil) {
			*error = error2;
		}
		return nil;
	}
	
	SPTListPage *newPage = [[SPTListPage alloc] initWithDecodedJSONObject:decodedObj
												 expectingPartialChildren:true
															rootObjectKey:@"albums"];
	return newPage;
}





///--------------------------
/// @name Convenience methods
///--------------------------

+(void)requestFeaturedPlaylistsForCountry:(NSString *)country
									limit:(NSInteger)limit
								   offset:(NSInteger)offset
								   locale:(NSString *)locale
								timestamp:(NSDate*)timestamp
							  accessToken:(NSString *)accessToken
						  accessTokenType:(NSString *)accessTokenType
								 callback:(SPTRequestCallback)block {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		NSURL *searchUrl = [NSURL URLWithString:SPTBrowseFeaturedPlaylistsAPIURL];
		NSError *err = nil;
		NSDictionary *values = [NSMutableDictionary dictionary];
		
		if (country != nil) {
			[values setValue:country forKey:@"country"];
		}
		if (locale != nil) {
			[values setValue:locale forKey:@"locale"];
		}
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
		if (timestamp != nil) {
			[values setValue:[formatter stringFromDate:timestamp] forKey:@"timestamp"];
		} else {
			[values setValue:[formatter stringFromDate:[NSDate date]] forKey:@"timestamp"];
		}
		
		[values setValue:@(limit) forKey:@"limit"];
		[values setValue:@(offset) forKey:@"offset"];

		NSData *returnData = [SPTRequest performRequestAtURL:searchUrl
											 withAccessToken:accessToken
											 accessTokenType:accessTokenType
											httpMethod:nil
												values:values
												 error:&err];

		if (err != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err, nil); });
			return;
		}
		
		id json = [NSJSONSerialization JSONObjectWithData:returnData options:0 error:&err];
		
		if (err != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err, nil); });
			return;
		}

        // We ignore any errors that might occur during creation of list of featured playlists.
		SPTFeaturedPlaylistList *page = [[SPTFeaturedPlaylistList alloc] initWithDecodedJSONObject:json];

		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, page); });
		
	});
}

+ (void)requestNewReleasesForCountry:(NSString *)country
							   limit:(NSInteger)limit
							  offset:(NSInteger)offset
						 accessToken:(NSString *)accessToken
							callback:(SPTRequestCallback)block {
	NSError *err = nil;
	NSURLRequest *req = [self createRequestForNewReleasesInCountry:country limit:limit offset:offset accessToken:accessToken error:&err];
	if (err != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err, nil); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		if (error != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error, nil); });
			return;
		}
		
		NSError *err2 = nil;
		SPTListPage *page = [SPTListPage listPageFromData:data
											 withResponse:response
								 expectingPartialChildren:YES
											rootObjectKey:@"albums"
													error:&err2];
		if (err2 != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err2, nil); });
			return;
		}
		
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, page); });
	}];
}










@end
