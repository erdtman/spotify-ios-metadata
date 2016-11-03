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

#import "SPTTrack.h"
#import "SPTJSONDecoding_Internal.h"
#import "SPTRequest_Internal.h"

static NSString * const SPTTrackJSONAlbumKey = @"album";
static NSString * const SPTTrackJSONPopularityKey = @"popularity";
static NSString * const SPTTrackJSONExternalIDsKey = @"external_ids";

@interface SPTTrack ()

@property (nonatomic, readwrite, copy) NSDictionary *externalIds;
@property (nonatomic, readwrite) double popularity;

@end

@implementation SPTTrack

+(void)load {
	[SPTJSONDecoding registerClass:self forJSONType:@"track"];
}







///----------------------------
/// @name API Request Factories
///----------------------------

+ (NSURLRequest *)createRequestForTrack:(NSURL *)uri
						withAccessToken:(NSString *)accessToken
								 market:(NSString *)market
								  error:(NSError *__autoreleasing *)error {
	
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	NSString *albumId = uriComponents[2];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/tracks/%@", albumId]];
	
	NSMutableDictionary *values = [NSMutableDictionary dictionary];
	if (market != nil)
		[values setValue:market forKey:@"market"];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+ (NSURLRequest *)createRequestForTracks:(NSArray *)uris
						 withAccessToken:(NSString *)accessToken
								  market:(NSString *)market
								   error:(NSError *__autoreleasing *)error {
	
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<uris.count; i++) {
		NSURL *uri = [uris objectAtIndex:i];
		NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
		if (uriComponents.count == 3 &&
			[uriComponents[0] isEqualToString:@"spotify"] &&
			[uriComponents[1] isEqualToString:@"track"]) {
			[ids addObject:uriComponents[2]];
		}
	}
	
	
	NSMutableDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];
	if (market != nil)
		[values setValue:market forKey:@"market"];
	NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/tracks"];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}













///---------------------------
/// @name API Response Parsers
///---------------------------

+ (NSArray*)tracksFromDecodedJSON:(id)decodedObject
							error:(NSError **)error {
	
	if (![decodedObject[@"tracks"] isKindOfClass:[NSArray class]]) {
		// TODO: Set error
		return nil;
	}
	
	NSArray *jsonChildren = decodedObject[@"tracks"];
	NSMutableArray *children = [NSMutableArray arrayWithCapacity:jsonChildren.count];
	for (id jsonChild in jsonChildren) {
		id decodedChild = [SPTTrack trackFromDecodedJSON:jsonChild error:error];
		if (error != nil && *error != nil) {
			return nil;
		}
		
		if (decodedChild != nil) {
			[children addObject:decodedChild];
		} else {
			[children addObject:[NSNull null]];
		}
	}
	return children;
}

-(id)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error {
	self = [super initWithDecodedJSONObject:decodedObject error:error];
	if (self) {
		if (decodedObject == nil) {
			return self;
		}
		
		if ([decodedObject isKindOfClass:[NSNull class]]) {
			return self;
		}
		
		if ([decodedObject[SPTTrackJSONPopularityKey] respondsToSelector:@selector(doubleValue)])
			self.popularity = [decodedObject[SPTTrackJSONPopularityKey] doubleValue];
		
		id externalIds = decodedObject[SPTTrackJSONExternalIDsKey];
		if ([externalIds isKindOfClass:[NSDictionary class]]) {
			
			NSMutableDictionary *newIds = [NSMutableDictionary new];
			for (NSString *externalIdKey in externalIds) {
				
				NSString *externalId = externalIds[externalIdKey];
				if (externalId.length > 0 && externalIdKey.length > 0)
					newIds[externalIdKey] = externalId;
			}
			
			self.externalIds = [NSDictionary dictionaryWithDictionary:newIds];
		}
		
		if ([decodedObject[SPTTrackJSONPopularityKey] respondsToSelector:@selector(doubleValue)]) {
			self.popularity = [decodedObject[SPTTrackJSONPopularityKey] doubleValue];
		}
		
	}
	return self;
}

+ (instancetype)trackFromData:(NSData *)data withResponse:(NSURLResponse *)response error:(NSError **)error {
	if (data == nil) {
		// TODO: set error
		return nil;
	}
	
	id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
	if (error != nil && *error != nil) {
		return nil;
	}
	
	return [SPTTrack trackFromDecodedJSON:decodedObj error:error];
	
}

+ (NSArray *)tracksFromData:(NSData *)data withResponse:(NSURLResponse *)response error:(NSError **)error {
	if (data == nil) {
		// TODO: set error
		return nil;
	}
	
	id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
	if (error != nil && *error != nil) {
		return nil;
	}
	
	return [SPTTrack tracksFromDecodedJSON:decodedObj error:error];
}

+ (instancetype)trackFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	return [[SPTTrack alloc] initWithDecodedJSONObject:decodedObject error:error];
}






///--------------------------
/// @name Convenience Methods
///--------------------------

+ (void)trackWithURI:(NSURL *)uri
		 accessToken:(NSString *)accessToken
			  market:(NSString *)market
			callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForTrack:uri withAccessToken:accessToken market:market error:&reqerr];
	
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *parseerr = nil;
		SPTTrack *track = [SPTTrack trackFromData:data withResponse:response error:&parseerr];
		
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(parseerr);
		SP_DISPATCH_ASYNC_BLOCK_RESULT(track);
	}];
	
}

+ (void)tracksWithURIs:(NSArray *)uris
		   accessToken:(NSString *)accessToken
				market:(NSString *)market
			  callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForTracks:uris withAccessToken:accessToken market:market error:&reqerr];
	
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *jsonerr = nil;
		id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonerr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(jsonerr);
		
		NSError *parseerr = nil;
		NSArray *tracks = [SPTTrack tracksFromDecodedJSON:jsonObj error:&parseerr];
		
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(parseerr);
		SP_DISPATCH_ASYNC_BLOCK_RESULT(tracks);
	}];
}

///--------------------
/// @name Miscellaneous
///--------------------

+ (BOOL)isTrackURI:(NSURL*)uri {
	if (uri == nil)
		return NO;
	
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 3)
		return NO;
	
	if (![uriComponents[0] isEqualToString:@"spotify"])
		return NO;
	
	if (![uriComponents[1] isEqualToString:@"track"])
		return NO;
	
	// TODO: validate base62
	
	return YES;
}

+ (NSString *)identifierFromURI:(NSURL *)uri {
	if (uri == nil)
		return nil;
	
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 3)
		return nil;
	
	if (![uriComponents[0] isEqualToString:@"spotify"])
		return nil;
	
	if (![uriComponents[1] isEqualToString:@"track"])
		return nil;
	
	// TODO: validate base62
	
	return uriComponents[2];
}

+ (NSArray*)identifiersFromArray:(NSArray *)tracks {
	NSMutableArray *output = [NSMutableArray array];
	
	for(int i=0; i<tracks.count; i++) {
		id item = [tracks objectAtIndex:i];
		
		if ([item isKindOfClass:[SPTPartialTrack class]]) {
			SPTPartialTrack *track = item;
			[output addObject:track.identifier];
		} else if ([item isKindOfClass:[NSURL class]]) {
			NSURL *uri = item;
			NSString *identifier = [SPTTrack identifierFromURI:uri];
			[output addObject:identifier];
		}
	}
	
	return output;
}

+ (NSArray*)urisFromArray:(NSArray *)tracks {
	NSMutableArray *output = [NSMutableArray array];
	
	for(int i=0; i<tracks.count; i++) {
		id item = [tracks objectAtIndex:i];
		
		if ([item isKindOfClass:[SPTPartialTrack class]]) {
			SPTPartialTrack *track = item;
			[output addObject:track.uri];
		} else if ([item isKindOfClass:[NSURL class]]) {
			NSURL *uri = item;
			[output addObject:uri];
		}
	}
	
	return output;
}

+ (NSArray*)uriStringsFromArray:(NSArray *)tracks {
	NSArray *uris = [self urisFromArray:tracks];
	return [uris valueForKeyPath:@"absoluteString"];
}

@end
