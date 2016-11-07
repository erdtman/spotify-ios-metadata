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

#import "SPTListPage.h"
#import "SPTListPage_Internal.h"
#import "SPTPlaylistList.h"
#import "SPTPlaylistSnapshot.h"
#import "SPTRequest.h"
#import "SPTRequest_Internal.h"

@implementation SPTPlaylistList

-(id)initWithDecodedJSONObject:(id)jsonObj {
	self = [super initWithDecodedJSONObject:jsonObj expectingPartialChildren:YES rootObjectKey:nil];
	if (self) {
		if (jsonObj == nil) {
			return self;
		}
		
		if ([jsonObj isKindOfClass:[NSNull class]]) {
			return self;
		}
	}
	return self;
}


+ (NSURLRequest *)createRequestForCreatingPlaylistWithName:(NSString *)name
												   forUser:(NSString *)username
											withPublicFlag:(BOOL)isPublic
											   accessToken:(NSString *)accessToken
													 error:(NSError **)error {
	
	NSURL *lookupUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists", [SPTRequest urlEncodeString:username]]];
	NSDictionary *values = @{
							 @"name" : name,
							 @"public" : @([[NSNumber numberWithBool:isPublic] boolValue])
							 };
	
	return [SPTRequest createRequestForURL:lookupUrl
						   withAccessToken:accessToken
								httpMethod:@"POST"
									values:values
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}


+ (void)createPlaylistWithName:(NSString *)name
					   forUser:(NSString *)username
					publicFlag:(BOOL)isPublic
				   accessToken:(NSString *)accessToken
					  callback:(SPTPlaylistCreationCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTPlaylistList createRequestForCreatingPlaylistWithName:name
																		  forUser:username
																   withPublicFlag:isPublic
																	  accessToken:accessToken
																			error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {

		NSError *err = nil;
		id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
		if (err != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err, nil); });
			return;
		}
		
		NSURL *uri = nil;
		if (json[@"uri"] != nil)
			uri = [NSURL URLWithString:json[@"uri"]];
		
		[SPTPlaylistSnapshot playlistWithURI:uri accessToken:accessToken callback:^(NSError *error, id object) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error, object); });
		}];
	}];
}

+ (NSURLRequest *)createRequestForGettingPlaylistsForUser:(NSString *)username
										  withAccessToken:(NSString *)accessToken
													error:(NSError **)error {
	NSURL *lookupUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists", [SPTRequest urlEncodeString:username]]];
	return [SPTRequest createRequestForURL:lookupUrl
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:nil
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:NO
									 error:error];

}

+ (void)playlistsForUser:(NSString *)username
		 withAccessToken:(NSString *)accessToken
				callback:(SPTRequestCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForGettingPlaylistsForUser:username
													  withAccessToken:accessToken
																error:&reqerr];
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		if(error) {
			block(error, nil);
		}
		else {
			NSError *parseerr = nil;
			SPTPlaylistList *list = [SPTPlaylistList playlistListFromData:data withResponse:response error:&parseerr];
			block(parseerr,list);
		}
	}];
}

+ (SPTPlaylistList *)playlistListFromData:(NSData *)data
							 withResponse:(NSURLResponse *)response
									error:(NSError **)error {
	NSError *err = nil;
	if(data != nil) {
		id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
		if (err != nil) {
			*error = err;
			return nil;
		}
		return [[SPTPlaylistList alloc] initWithDecodedJSONObject:json];
	}
	return nil;
}

+ (instancetype)playlistListFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	return [[SPTPlaylistList alloc] initWithDecodedJSONObject:decodedObject];
}

@end

