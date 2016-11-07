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

#import "SPTPlaylistSnapshot.h"
#import "SPTRequest.h"
#import "SPTRequest_Internal.h"
#import "SPTJSONDecoding_Internal.h"
#import "SPTListPage.h"
#import "SPTListPage_Internal.h"
#import "SPTUser.h"
#import "SPTTrack.h"
#import "SPTImage.h"
#import "SPTImage_Internal.h"

NSString * const SPTPlaylistSnapshotPublicKey = @"public";
NSString * const SPTPlaylistSnapshotNameKey = @"name";

static NSString * const SPTPlaylistJSONIdKey = @"id";
static NSString * const SPTPlaylistJSONNameKey = @"name";
static NSString * const SPTPlaylistJSONURIKey = @"uri";
static NSString * const SPTPlaylistJSONTracksKey = @"tracks";
static NSString * const SPTPlaylistJSONSnapshotIdKey = @"snapshot_id";
static NSString * const SPTPlaylistJSONFollowersKey = @"followers";
static NSString * const SPTPlaylistJSONFollowersTotalKey = @"total";
static NSString * const SPTPlaylistJSONDescriptionKey = @"description";

@interface SPTPlaylistSnapshot ()

@property (nonatomic, readwrite) SPTListPage *firstTrackPage;
@property (nonatomic, readwrite) NSString *snapshotId;
@property (nonatomic, readwrite) long followerCount;
@property (nonatomic, readwrite, copy) NSString *descriptionText;

@end

@implementation SPTPlaylistSnapshot

+(void)load {
	[SPTJSONDecoding registerClass:self forJSONType:@"playlist"];
}

-(id)initWithDecodedJSONObject:(id)decodedObject
						 error:(NSError **)error {
	
	self = [super initWithDecodedJSONObject:decodedObject error:error];
	
	if (self) {
		// We're given an object from JSON, so be extra careful when decoding stuff.
		
		if ([decodedObject[SPTPlaylistJSONTracksKey] isKindOfClass:[NSDictionary class]]) {
			self.firstTrackPage = [[SPTListPage alloc] initWithDecodedJSONObject:decodedObject[SPTPlaylistJSONTracksKey]
														expectingPartialChildren:YES
																   rootObjectKey:nil];
		}
		
		if (![decodedObject[SPTPlaylistJSONSnapshotIdKey] isEqual:[NSNull null]])
			self.snapshotId = [NSString stringWithFormat:@"%@", decodedObject[SPTPlaylistJSONSnapshotIdKey]];
		
		if (![decodedObject[SPTPlaylistJSONDescriptionKey] isEqual:[NSNull null]])
			self.descriptionText = [NSString stringWithFormat:@"%@", decodedObject[SPTPlaylistJSONDescriptionKey]];
		
		if (![decodedObject[SPTPlaylistJSONFollowersKey] isEqual:[NSNull null]] &&
			![decodedObject[SPTPlaylistJSONFollowersKey][SPTPlaylistJSONFollowersTotalKey] isEqual:[NSNull null]]) {
			NSNumber *total = decodedObject[SPTPlaylistJSONFollowersKey][SPTPlaylistJSONFollowersTotalKey];
			self.followerCount = [total longValue];
		}
	}
	
	return self;
}

+ (instancetype)playlistSnapshotFromData:(NSData *)data
							withResponse:(NSURLResponse *)response
								   error:(NSError **)error {
	
	NSError *err = nil;
	id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
	if (err != nil) {
		if (error != nil) *error = err;
		return nil;
	}
	
	return [self playlistSnapshotFromDecodedJSON:json
										   error:error];
}

+ (instancetype)playlistSnapshotFromDecodedJSON:(id)decodedObject
										  error:(NSError **)error {
	return [[SPTPlaylistSnapshot alloc] initWithDecodedJSONObject:decodedObject
															error:error];
}

+ (NSURLRequest *)createRequestForPlaylistWithURI:(NSURL *)uri
									  accessToken:(NSString *)accessToken
											error:(NSError **)error {
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	
	if (uriComponents.count < 4 ||
		uriComponents.count > 5) {
		[SPTRequest setErrorCode:401 withDescription:@"Invalid Playlist URI" toError:error];
		return nil;
	}
	
	if (![[uriComponents objectAtIndex:0] isEqualToString:@"spotify"] ||
		![[uriComponents objectAtIndex:1] isEqualToString:@"user"]) {
		[SPTRequest setErrorCode:401 withDescription:@"Invalid Playlist URI" toError:error];
		return nil;
	}
	
	if (uriComponents.count == 4) {
		NSString *userName = nil;
		
		if (![[uriComponents objectAtIndex:3] isEqualToString:@"starred"]) {
			[SPTRequest setErrorCode:401 withDescription:@"Invalid Playlist URI" toError:error];
			return nil;
		}
		
		userName = uriComponents[2];
		NSString *apiurl = [NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/starred", userName];
		return [SPTRequest createRequestForURL:[NSURL URLWithString:apiurl] withAccessToken:accessToken error:error];
	}
	else if (uriComponents.count == 5) {
		NSString *userName = nil;
		NSString *playlistId = nil;
		
		if (![[uriComponents objectAtIndex:3] isEqualToString:@"playlist"]) {
			[SPTRequest setErrorCode:401 withDescription:@"Invalid Playlist URI" toError:error];
			return nil;
		}
		
		userName = uriComponents[2];
		playlistId = uriComponents[4];
		NSString *apiurl = [NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists/%@", userName, playlistId];
		return [SPTRequest createRequestForURL:[NSURL URLWithString:apiurl] withAccessToken:accessToken error:error];
	}
	else {
		return nil;
	}
}

+ (void)playlistWithURI:(NSURL *)uri
			accessToken:(NSString *)accessToken
			   callback:(SPTRequestCallback)block {
	NSError *reqerr = nil;
	
	NSURLRequest *req = [self createRequestForPlaylistWithURI:uri accessToken:accessToken error:&reqerr];
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *parseerr = nil;
		SPTPlaylistSnapshot *list = [SPTPlaylistSnapshot playlistSnapshotFromData:data withResponse:response error:&parseerr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(parseerr);
		
		SP_DISPATCH_ASYNC_BLOCK_RESULT(list);
	}];
}

+(void)playlistsWithURIs:(NSArray *)uris
			 accessToken:(NSString *)accessToken
				callback:(SPTRequestCallback)block {
	
	[SPTRequest performSequentialMultiget:uris pager:^(NSArray *inputs, SPTRequestCallback pagecallback) {
		// fake multi-get for playlists, will do one request per playlist.
		[SPTPlaylistSnapshot playlistWithURI:[inputs objectAtIndex:0] accessToken:accessToken callback:^(NSError *error, id object) {
			pagecallback(error, @[ object != nil ? object : [NSNull null] ]);
		}];
	} pagesize:1 callback:block];
}

+(BOOL)isPlaylistURI:(NSURL*)uri {
	if (uri == nil) {
		return false;
	}
	
	if (![uri respondsToSelector:@selector(absoluteString)]) {
		return false;
	}
	
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 5) {
		return false;
	}
	
	if (![uriComponents[0] isEqualToString:@"spotify"]) {
		return false;
	}
	
	if (![uriComponents[1] isEqualToString:@"user"]) {
		return false;
	}
	
	if (![uriComponents[3] isEqualToString:@"playlist"]) {
		return false;
	}
	
	return true;
}

+(BOOL)isStarredURI:(NSURL*)uri {
	if (uri == nil)
		return false;
	
	if (![uri respondsToSelector:@selector(absoluteString)])
		return false;
	
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 4)
		return false;
	
	if (![uriComponents[0] isEqualToString:@"spotify"])
		return false;
	
	if (![uriComponents[1] isEqualToString:@"user"])
		return false;
	
	if (![uriComponents[3] isEqualToString:@"starred"])
		return false;
	
	return true;
}





-(NSArray *)tracksForPlayback {
	return self.firstTrackPage.items;
}

#pragma mark -

+ (NSURLRequest *)createRequestForAddingTracks:(NSArray *)tracks
									atPosition:(int)position
									toPlaylist:(NSURL *)playlist
							   withAccessToken:(NSString *)accessToken
										 error:(NSError **)error {
	NSString *userName = nil;
	NSString *playlistId = nil;
	
	NSArray *uriComponents = [[playlist absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count == 5) {
		userName = uriComponents[2];
		playlistId = uriComponents[4];
	}
	
	NSArray *trackURIs = [SPTTrack uriStringsFromArray:tracks];
	NSURL *postUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists/%@/tracks", userName, playlistId]];
	
	return [SPTRequest createRequestForURL:postUrl
						   withAccessToken:accessToken
								httpMethod:@"POST"
									values:@{
											 @"uris": trackURIs,
											 @"position": [NSNumber numberWithInt:position]
											 }
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}


+ (NSURLRequest *)createRequestForAddingTracks:(NSArray *)tracks
									toPlaylist:(NSURL *)playlist
							   withAccessToken:(NSString *)accessToken
										 error:(NSError **)error {
	
	NSString *userName = nil;
	NSString *playlistId = nil;
	
	NSArray *uriComponents = [[playlist absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count == 5) {
		userName = uriComponents[2];
		playlistId = uriComponents[4];
	}
	
	NSArray *trackURIs = [SPTTrack uriStringsFromArray:tracks];
	NSURL *postUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists/%@/tracks", userName, playlistId]];
	
	return [SPTRequest createRequestForURL:postUrl
						   withAccessToken:accessToken
								httpMethod:@"POST"
									values:trackURIs
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}

-(void)addTracksToPlaylist:(NSArray *)tracks
		   withAccessToken:(NSString *)accessToken
				  callback:(SPTMetadataErrorableOperationCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForAddingTracks:tracks toPlaylist:self.uri withAccessToken:accessToken error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req
									  callback:^(NSError *error, NSURLResponse *response, NSData *data) {
										  if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
									  }];
}


- (void)addTracksWithPositionToPlaylist:(NSArray *)tracks
						   withPosition:(int)position
							accessToken:(NSString *)accessToken
							   callback:(SPTMetadataErrorableOperationCallback)block

{
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForAddingTracks:tracks
															   atPosition:position
															   toPlaylist:self.uri
														  withAccessToken:accessToken
																	error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req
									  callback:^(NSError *error, NSURLResponse *response, NSData *data) {
										  if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
									  }];
}

+ (NSURLRequest *)createRequestForChangingDetails:(NSDictionary *)data
									   inPlaylist:(NSURL *)playlist
								  withAccessToken:(NSString *)accessToken
											error:(NSError **)error {
	
	NSString *userName = nil;
	NSString *playlistId = nil;
	
	NSArray *uriComponents = [[playlist absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count == 5) {
		userName = uriComponents[2];
		playlistId = uriComponents[4];
	}
	
	NSMutableDictionary *data2 = [NSMutableDictionary dictionaryWithDictionary:data];
	
	if ([data2 objectForKey:@"public"] != nil) {
		if ([[data2 objectForKey:@"public"] respondsToSelector:@selector(boolValue)]) {
			bool b = [[data2 objectForKey:@"public"] boolValue];
			[data2 setValue:@([[NSNumber numberWithBool:b] boolValue]) forKey:@"public"];
		}
	}
	
	
	NSURL *putUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists/%@", userName, playlistId]];
	
	return [SPTRequest createRequestForURL:putUrl
						   withAccessToken:accessToken
								httpMethod:@"PUT"
									values:data2
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}

-(void)changePlaylistDetails:(NSDictionary *)data
			 withAccessToken:(NSString *)accessToken
					callback:(SPTMetadataErrorableOperationCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForChangingDetails:data
																  inPlaylist:self.uri
															 withAccessToken:accessToken
																	   error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req
									  callback:^(NSError *error, NSURLResponse *response, NSData *data) {
										  if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
									  }];
}

+ (NSURLRequest *)createRequestForSettingTracks:(NSArray *)tracks
									 inPlaylist:(NSURL *)playlist
								withAccessToken:(NSString *)accessToken
										  error:(NSError *__autoreleasing *)error {
	NSString *userName = nil;
	NSString *playlistId = nil;
	
	NSArray *uriComponents = [[playlist absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count == 5) {
		userName = uriComponents[2];
		playlistId = uriComponents[4];
	}
	
	NSArray *trackURIs = [SPTTrack uriStringsFromArray:tracks];
	NSURL *putUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists/%@/tracks", userName, playlistId]];
	
	return [SPTRequest createRequestForURL:putUrl
						   withAccessToken:accessToken
								httpMethod:@"PUT"
									values:@{@"uris": trackURIs}
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}

- (void)replaceTracksInPlaylist:(NSArray *)tracks
				withAccessToken:(NSString *)accessToken
					   callback:(SPTMetadataErrorableOperationCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForSettingTracks:tracks
																inPlaylist:self.uri
														   withAccessToken:accessToken
																	 error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req
									  callback:^(NSError *error, NSURLResponse *response, NSData *data) {
										  if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
									  }];
}

+ (NSURLRequest *)createRequestForRemovingTracks:(NSArray *)tracks
									fromPlaylist:(NSURL *)playlist
								 withAccessToken:(NSString *)accessToken
										snapshot:(NSString *)snapshotId
										   error:(NSError **)error {
	NSString *userName = nil;
	NSString *playlistId = nil;
	
	NSArray *uriComponents = [[playlist absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count == 5) {
		userName = uriComponents[2];
		playlistId = uriComponents[4];
	}
	
	NSURL *deleteUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists/%@/tracks", userName, playlistId]];
	
	NSMutableArray *trackInfo = [[NSMutableArray alloc] init];
	NSArray *trackUris = [SPTTrack uriStringsFromArray:tracks];
	for (id obj in trackUris) {
		[trackInfo addObject:@{@"uri": obj}];
	}
	
	NSError *err = nil;
	return [SPTRequest createRequestForURL:deleteUrl
						   withAccessToken:accessToken
								httpMethod:@"DELETE"
									values:@{
											 @"tracks": trackInfo,
											 @"snapshot_id": snapshotId
											 }
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:&err];
}

-(void)removeTracksFromPlaylist:(NSArray *)tracks
				withAccessToken:(NSString *)accessToken
					   callback:(SPTMetadataErrorableOperationCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForRemovingTracks:tracks
															   fromPlaylist:self.uri
															withAccessToken:accessToken
																   snapshot:self.snapshotId
																	  error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
	}];
}

+ (NSURLRequest *)createRequestForRemovingTracksWithPositions:(NSArray *)tracks
												 fromPlaylist:(NSURL *)playlist
											  withAccessToken:(NSString *)accessToken
													 snapshot:(NSString *)snapshotId
														error:(NSError **)error {
	NSString *userName = nil;
	NSString *playlistId = nil;
	NSArray *uriComponents = [[playlist absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count == 5) {
		userName = uriComponents[2];
		playlistId = uriComponents[4];
	}
	
	NSURL *deleteUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists/%@/tracks", userName, playlistId]];
	
	NSMutableArray *trackInfo = [[NSMutableArray alloc] init];
	for (id obj in tracks) {
		id track = [obj objectForKey:@"track"];
		NSArray *trackUris = [SPTTrack uriStringsFromArray:@[track]];
		[trackInfo addObject:@{@"uri": [trackUris objectAtIndex:0],
							   @"positions": [obj objectForKey:@"positions"]}];
	}
	
	NSArray *array = [trackInfo copy];
	return [SPTRequest createRequestForURL:deleteUrl
						   withAccessToken:accessToken
								httpMethod:@"DELETE"
									values:@{@"snapshot_id": snapshotId, @"tracks": array}
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}

-(void)removeTracksWithPositionsFromPlaylist:(NSArray *)tracks
							 withAccessToken:(NSString *)accessToken
									callback:(SPTMetadataErrorableOperationCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTPlaylistSnapshot createRequestForRemovingTracksWithPositions:tracks
																			fromPlaylist:self.uri
																		withAccessToken:accessToken
																				snapshot:self.snapshotId
																				   error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
	}];
}

+ (void)requestStarredListForUser:(NSString *)username
				  withAccessToken:(NSString *)accessToken
						 callback:(SPTRequestCallback)block {
	NSURL *uri = [NSURL URLWithString:[NSString stringWithFormat:@"spotify:user:%@:starred", [SPTRequest urlEncodeString:username]]];
	[SPTPlaylistSnapshot playlistWithURI:uri accessToken:accessToken callback:block];
}

@end
