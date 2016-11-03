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

#import "SPTFollow.h"
#import "SPTRequest.h"
#import "SPTRequest_Internal.h"

static NSString * const SPTFollowMeFollowingAPIURL = @"https://api.spotify.com/v1/me/following";
static NSString * const SPTFollowMeFollowingContainsAPIURL = @"https://api.spotify.com/v1/me/following/contains";
static NSString * const SPTFollowUserPlaylistsFollowersAPIURLFormat = @"https://api.spotify.com/v1/users/%@/playlists/%@/followers";
static NSString * const SPTFollowUserPlaylistsFollowersContainsAPIURLFormat = @"https://api.spotify.com/v1/users/%@/playlists/%@/followers/contains";

static NSString * const SPTPlaylistTrackJSONAddedAtKey = @"added_at";

@implementation SPTFollow







///----------------------------
/// @name API Request Factories
///----------------------------

+ (NSURLRequest*)createRequestForFollowingArtists:(NSArray*)artistUris
								  withAccessToken:(NSString *)accessToken
											error:(NSError **)error {
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<artistUris.count; i++) {
		NSURL *artistUri = [artistUris objectAtIndex:i];
		NSArray *uriComponents = [[artistUri absoluteString] componentsSeparatedByString:SPTFollowMeFollowingAPIURL];
		if (uriComponents.count != 3) {
			return nil;
		}
		[ids addObject:[SPTRequest urlEncodeString:uriComponents[2]]];
	}
	
	NSURL *url = [NSURL URLWithString:SPTFollowMeFollowingAPIURL];
	NSDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:@"artist" forKey:@"type"];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"PUT"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}


+ (NSURLRequest*)createRequestForUnfollowingArtists:(NSArray*)artistUris
									withAccessToken:(NSString *)accessToken
											  error:(NSError **)error {
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<artistUris.count; i++) {
		NSURL *artistUri = [artistUris objectAtIndex:i];
		NSArray *uriComponents = [[artistUri absoluteString] componentsSeparatedByString:@":"];
		if (uriComponents.count != 3) {
			return nil;
		}
		[ids addObject:[SPTRequest urlEncodeString:uriComponents[2]]];
	}
	
	NSURL *url = [NSURL URLWithString:SPTFollowMeFollowingAPIURL];
	NSDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:@"artist" forKey:@"type"];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"DELETE"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+ (NSURLRequest*)createRequestForCheckingIfFollowingArtists:(NSArray*)artistUris
											withAccessToken:(NSString *)accessToken
													  error:(NSError **)error {
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<artistUris.count; i++) {
		NSURL *artistUri = [artistUris objectAtIndex:i];
		NSArray *uriComponents = [[artistUri absoluteString] componentsSeparatedByString:@":"];
		if (uriComponents.count != 3) {
			return nil;
		}
		[ids addObject:[SPTRequest urlEncodeString:uriComponents[2]]];
	}
	
	NSURL *url = [NSURL URLWithString:SPTFollowMeFollowingContainsAPIURL];
	NSDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:@"artist" forKey:@"type"];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];

	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
									 error:error];
}






+ (NSURLRequest*)createRequestForFollowingUsers:(NSArray*)usernames
								withAccessToken:(NSString *)accessToken
										  error:(NSError **)error {
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<usernames.count; i++) {
		NSString *username = [usernames objectAtIndex:i];
		[ids addObject:[SPTRequest urlEncodeString:username]];
	}
	
	NSURL *searchUrl = [NSURL URLWithString:SPTFollowMeFollowingAPIURL];
	NSDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:@"user" forKey:@"type"];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];
	
	return [SPTRequest createRequestForURL:searchUrl
						   withAccessToken:accessToken
								httpMethod:@"PUT"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+ (NSURLRequest*)createRequestForUnfollowingUsers:(NSArray*)usernames
								  withAccessToken:(NSString *)accessToken
											error:(NSError **)error {
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<usernames.count; i++) {
		NSString *username = [usernames objectAtIndex:i];
		[ids addObject:[SPTRequest urlEncodeString:username]];
	}
	
	NSURL *searchUrl = [NSURL URLWithString:SPTFollowMeFollowingAPIURL];
	NSDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:@"user" forKey:@"type"];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];

	return [SPTRequest createRequestForURL:searchUrl
						   withAccessToken:accessToken
								httpMethod:@"DELETE"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+ (NSURLRequest*)createRequestForCheckingIfFollowingUsers:(NSArray*)usernames
										  withAccessToken:(NSString *)accessToken
													error:(NSError **)error {
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<usernames.count; i++) {
		NSString *username = [usernames objectAtIndex:i];
		[ids addObject:[SPTRequest urlEncodeString:username]];
	}
	
	NSURL *searchUrl = [NSURL URLWithString:SPTFollowMeFollowingAPIURL];
	NSDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:@"artist" forKey:@"type"];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];
	
	return [SPTRequest createRequestForURL:searchUrl
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
									 error:error];
}





+ (NSURLRequest*)createRequestForFollowingPlaylist:(NSURL *)playlistUri
								   withAccessToken:(NSString *)accessToken
											secret:(BOOL)secret
											 error:(NSError **)error {
	NSArray *uriComponents = [[playlistUri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 5) {
		return nil;
	}
	
	if (![uriComponents[0] isEqualToString:@"spotify"] ||
		![uriComponents[1] isEqualToString:@"user"] ||
		![uriComponents[3] isEqualToString:@"playlist"]) {
		return nil;
	}
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:SPTFollowUserPlaylistsFollowersAPIURLFormat, [SPTRequest urlEncodeString:uriComponents[2]], [SPTRequest urlEncodeString: uriComponents[4]]]];
	NSDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:@([[NSNumber numberWithBool:!secret] boolValue]) forKey:@"public"];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"PUT"
									values:values
						   valueBodyIsJSON:YES
					 sendDataAsQueryString:NO
									 error:error];
}

+ (NSURLRequest*)createRequestForUnfollowingPlaylist:(NSURL*)playlistUri
									 withAccessToken:(NSString *)accessToken
											   error:(NSError **)error {
	NSArray *uriComponents = [[playlistUri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 5) {
		return nil;
	}
	
	if (![uriComponents[0] isEqualToString:@"spotify"] ||
		![uriComponents[1] isEqualToString:@"user"] ||
		![uriComponents[3] isEqualToString:@"playlist"]) {
		return nil;
	}
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: SPTFollowUserPlaylistsFollowersAPIURLFormat, [SPTRequest urlEncodeString:uriComponents[2]], [SPTRequest urlEncodeString: uriComponents[4]]]];
	NSDictionary *values = [NSMutableDictionary dictionary];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"DELETE"
									values:values
									 error:error];
}

+ (NSURLRequest*)createRequestForCheckingIfUsers:(NSArray *)usernames
							areFollowingPlaylist:(NSURL*)playlistUri
								 withAccessToken:(NSString *)accessToken
										   error:(NSError **)error {
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<usernames.count; i++) {
		NSString *username = [usernames objectAtIndex:i];
		[ids addObject:[SPTRequest urlEncodeString:username]];
	}

	NSArray *uriComponents = [[playlistUri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 5) {
		return nil;
	}

	if (![uriComponents[0] isEqualToString:@"spotify"] ||
		![uriComponents[1] isEqualToString:@"user"] ||
		![uriComponents[3] isEqualToString:@"playlist"]) {
		return nil;
	}
	
	NSString *qs = [ids componentsJoinedByString:@","];
		
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: SPTFollowUserPlaylistsFollowersContainsAPIURLFormat, [SPTRequest urlEncodeString:uriComponents[2]], [SPTRequest urlEncodeString: uriComponents[4]]]];
	NSDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:qs forKey:@"ids"];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
									 error:error];
}








///---------------------------
/// @name API Response Parsers
///---------------------------

+ (NSArray*)followingResultFromData:(NSData *)data
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
	
	if (![decodedObj isKindOfClass:[NSArray class]]) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"Decoded JSON is not an array."];
		}

		return nil;
	}
	
	return (NSArray *)decodedObj;
}


@end
