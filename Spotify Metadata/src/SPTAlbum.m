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

#import "SPTAlbum.h"
#import "SPTJSONDecoding.h"
#import "SPTJSONDecoding_Internal.h"
#import "SPTRequest.h"
#import "SPTRequest_Internal.h"
#import "SPTPartialArtist.h"
#import "SPTImage.h"
#import "SPTImage_Internal.h"
#import "SPTListPage.h"
#import "SPTListPage_Internal.h"

static NSString * const SPTAlbumJSONArtistsKey = @"artists";
static NSString * const SPTAlbumJSONExternalIDsKey = @"external_ids";
static NSString * const SPTAlbumJSONGenresKey = @"genres";
static NSString * const SPTAlbumJSONPopularityKey = @"popularity";
static NSString * const SPTAlbumJSONTracksKey = @"tracks";
static NSString * const SPTAlbumJSONReleaseDateKey = @"release_date";

static NSString * const SPTAlbumJSONNameKey = @"name";
static NSString * const SPTAlbumJSONURIKey = @"uri";
static NSString * const SPTAlbumJSONAlbumTypeKey = @"album_type";
static NSString * const SPTAlbumJSONAvailableMarketsKey = @"available_markets";
static NSString * const SPTAlbumJSONExternalURLsKey = @"external_urls";
static NSString * const SPTAlbumJSONExternalURLSpotifyKey = @"spotify";

@interface SPTAlbum ()

@property (nonatomic, readwrite, copy) NSDictionary *externalIds;
@property (nonatomic, readwrite) NSArray *artists;
@property (nonatomic, readwrite) SPTListPage *firstTrackPage;
@property (nonatomic, readwrite) NSInteger releaseYear;
@property (nonatomic, readwrite) NSDate *releaseDate;
@property (nonatomic, readwrite, copy) NSArray *genres;
@property (nonatomic, readwrite) double popularity;

@end

@implementation SPTAlbum

+(void)load {
	[SPTJSONDecoding registerClass:self forJSONType:@"album"];
}






+ (NSURLRequest *)createRequestForAlbum:(NSURL *)uri withAccessToken:(NSString *)accessToken market:(NSString *)market error:(NSError *__autoreleasing *)error {
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	NSString *albumId = uriComponents[2];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/albums/%@", albumId]];
	
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

+ (NSURLRequest *)createRequestForAlbums:(NSArray *)uris withAccessToken:(NSString *)accessToken market:(NSString *)market error:(NSError *__autoreleasing *)error {
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<uris.count; i++) {
		NSURL *uri = [uris objectAtIndex:i];
		NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
		if (uriComponents.count == 3 &&
			[uriComponents[0] isEqualToString:@"spotify"] &&
			[uriComponents[1] isEqualToString:@"album"]) {
			[ids addObject:uriComponents[2]];
		}
	}
	
	NSMutableDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];
	if (market != nil)
		[values setValue:market forKey:@"market"];
	NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/albums"];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}









+ (instancetype)albumFromData:(NSData *)data withResponse:(NSURLResponse *)response error:(NSError **)error {
	id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
	if (*error != nil) {
		return nil;
	}
	
	return [self albumFromDecodedJSON:jsonObj error:error];
}

+ (instancetype)albumFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	return [[SPTAlbum alloc] initWithDecodedJSONObject:decodedObject error:error];
}

+ (NSArray*)albumsFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	
	if (![decodedObject[@"albums"] isKindOfClass:[NSArray class]]) {
		// TODO: Set error
		return nil;
	}
	
	NSArray *jsonChildren = decodedObject[@"albums"];
	NSMutableArray *children = [NSMutableArray arrayWithCapacity:jsonChildren.count];
	for (id jsonChild in jsonChildren) {
		id decodedChild = [SPTAlbum albumFromDecodedJSON:jsonChild error:error];
		if (*error != nil) {
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

+(void)albumWithURI:(NSURL *)uri
		accessToken:(NSString *)accessToken
			 market:(NSString *)market
		   callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForAlbum:uri withAccessToken:accessToken market:market error:&reqerr];
	
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *parseerr = nil;
		SPTAlbum *album = [SPTAlbum albumFromData:data withResponse:response error:&parseerr];
		
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(parseerr);
		SP_DISPATCH_ASYNC_BLOCK_RESULT(album);
	}];
}

+(void)albumsWithURIs:(NSArray *)uris accessToken:(NSString *)accessToken market:(NSString *)market callback:(SPTRequestCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForAlbums:uris withAccessToken:accessToken market:market error:&reqerr];
	
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *jsonerr = nil;
		id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonerr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(jsonerr);
		
		NSError *parseerr = nil;
		NSArray *list = [SPTAlbum albumsFromDecodedJSON:jsonObj error:&parseerr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(parseerr);
		SP_DISPATCH_ASYNC_BLOCK_RESULT(list);
	}];
}

+(BOOL)isAlbumURI:(NSURL*)uri {
	if (uri == nil)
		return NO;
	
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 3)
		return NO;
	
	if (![uriComponents[0] isEqualToString:@"spotify"])
		return NO;
	
	if (![uriComponents[1] isEqualToString:@"album"])
		return NO;
	
	// TODO: validate base62
	
	return YES;
}

-(id)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error {
	self = [super initWithDecodedJSONObject:decodedObject error:error];
	if (self) {
		
		if ([decodedObject[SPTAlbumJSONReleaseDateKey] isKindOfClass:[NSString class]]) {
			
			NSString *jsonDate = decodedObject[SPTAlbumJSONReleaseDateKey];
			NSArray *dateComponents = [jsonDate componentsSeparatedByString:@"-"];
			
			if (dateComponents.count >= 1) {
				self.releaseYear = [dateComponents[0] integerValue];
			}
			if (dateComponents.count >= 3) {
				NSDateComponents *components = [[NSDateComponents alloc] init];
				components.day = [dateComponents[2] integerValue];
				components.month = [dateComponents[1] integerValue];
				components.year = [dateComponents[0] integerValue];
				NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
				self.releaseDate = [gregorian dateFromComponents:components];
			}
		}
		
		if ([decodedObject[SPTAlbumJSONPopularityKey] respondsToSelector:@selector(doubleValue)])
			self.popularity = [decodedObject[SPTAlbumJSONPopularityKey] doubleValue];
		
		if ([decodedObject[SPTAlbumJSONArtistsKey] isKindOfClass:[NSArray class]]) {
			
			NSArray *artists = decodedObject[SPTAlbumJSONArtistsKey];
			NSMutableArray *decodedArtists = [NSMutableArray arrayWithCapacity:artists.count];
			
			for (id obj in artists) {
				id decodedItem = [SPTJSONDecoding partialSPObjectFromDecodedJSON:obj error:nil];
				if (decodedItem != nil) {
					[decodedArtists addObject:decodedItem];
				}
			}
			
			self.artists = [NSArray arrayWithArray:decodedArtists];
		}
		
		if ([decodedObject[SPTAlbumJSONGenresKey] isKindOfClass:[NSArray class]]) {
			self.genres = decodedObject[SPTAlbumJSONGenresKey];
		}
		
		id externalIds = decodedObject[SPTAlbumJSONExternalIDsKey];
		
		if ([externalIds isKindOfClass:[NSDictionary class]]) {
			
			NSMutableDictionary *newIds = [NSMutableDictionary new];
			for (NSString *externalIdKey in externalIds) {
				
				NSString *externalId = externalIds[externalIdKey];
				if (externalId.length > 0 && externalIdKey.length > 0)
					newIds[externalIdKey] = externalId;
			}
			
			self.externalIds = [NSDictionary dictionaryWithDictionary:newIds];
		}
		
		if ([decodedObject[SPTAlbumJSONTracksKey] isKindOfClass:[NSDictionary class]])
			self.firstTrackPage = [[SPTListPage alloc] initWithDecodedJSONObject:decodedObject[SPTAlbumJSONTracksKey] expectingPartialChildren:YES
																   rootObjectKey:nil];
	}
	return self;
}

-(NSArray *)tracksForPlayback {
	return self.firstTrackPage.items;
}

@end
