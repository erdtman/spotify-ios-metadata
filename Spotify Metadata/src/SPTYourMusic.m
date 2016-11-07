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

#import "SPTYourMusic.h"
#import "SPTTrack.h"
#import "SPTRequest_Internal.h"
#import "SPTListPage.h"
#import "SPTListPage_Internal.h"

@implementation SPTYourMusic


+ (NSURLRequest*)createRequestForCurrentUsersSavedTracksWithAccessToken:(NSString *)accessToken
																  error:(NSError **)error {
	NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/me/tracks"];
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
									 error:error];
}

+ (void)savedTracksForUserWithAccessToken:(NSString *)accessToken
								 callback:(SPTRequestCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForCurrentUsersSavedTracksWithAccessToken:accessToken
																			   error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}

	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		if (error != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error, nil); });
			return;
		}

		NSError *err2 = nil;
		id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err2];
		if (err2 != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err2, nil); });
			return;
		}
		
		id page = [[SPTListPage alloc] initWithDecodedJSONObject:json
										expectingPartialChildren:NO
												   rootObjectKey:nil];
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, page); });
	}];
}





+ (NSURLRequest*)createRequestForSavingTracks:(NSArray *)tracks
					   forUserWithAccessToken:(NSString *)accessToken
										error:(NSError **)error {
	NSArray *trackIds = [SPTTrack identifiersFromArray:tracks];
	NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/me/tracks"];
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"PUT"
									values:trackIds
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}

+ (void)saveTracks:(NSArray *)tracks
forUserWithAccessToken:(NSString *)accessToken
		  callback:(SPTRequestCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForSavingTracks:tracks forUserWithAccessToken:accessToken error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		if (error != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error, nil); });
			return;
		}
		
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, data); });
	}];
}





+ (NSURLRequest*)createRequestForCheckingIfSavedTracksContains:(NSArray *)tracks
										forUserWithAccessToken:(NSString *)accessToken
														 error:(NSError **)error {
	NSArray *trackIds = [SPTTrack identifiersFromArray:tracks];
	NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/me/tracks/contains"];
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:@{@"ids": [trackIds componentsJoinedByString:@","]}
						   valueBodyIsJSON:NO
									 error:error];
}

+ (void)savedTracksContains:(NSArray *)tracks
	 forUserWithAccessToken:(NSString *)accessToken
				   callback:(SPTRequestCallback)block {
	NSArray *trackIds = [SPTTrack identifiersFromArray:tracks];
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForCheckingIfSavedTracksContains:trackIds forUserWithAccessToken:accessToken error:&reqerr];
	if (req == nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		if (error != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error, nil); });
			return;
		}
		
		NSError *err2 = nil;
		id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err2];
		if (err2 != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err2, nil); });
			return;
		}
		
		NSArray *fetchedArr = (NSArray*) json;
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, fetchedArr); });
	}];
}





+ (NSURLRequest*)createRequestForRemovingTracksFromSaved:(NSArray *)tracks
								  forUserWithAccessToken:(NSString *)accessToken
												   error:(NSError **)error {
	NSArray *trackIds = [SPTTrack identifiersFromArray:tracks];
	NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/me/tracks"];
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"DELETE"
									values:trackIds
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}

+ (void)removeTracksFromSaved:(NSArray *)tracks
	   forUserWithAccessToken:(NSString *)accessToken
					 callback:(SPTRequestCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForRemovingTracksFromSaved:tracks
											   forUserWithAccessToken:accessToken
																error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		NSError *err = nil;
		
		if (err != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err, nil); });
			return;
		}

		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, data); });
	}];
}









@end
