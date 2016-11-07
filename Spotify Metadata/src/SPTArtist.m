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

#import "SPTArtist.h"
#import "SPTRequest.h"
#import "SPTRequest_Internal.h"
#import "SPTJSONDecoding_Internal.h"
#import "SPTImage.h"
#import "SPTImage_Internal.h"
#import "SPTListPage.h"
#import "SPTListPage_Internal.h"
#import "SPTTrack.h"

static NSString * const SPTArtistJSONIDKey = @"id";
static NSString * const SPTArtistJSONNameKey = @"name";
static NSString * const SPTArtistJSONAlbumsKey = @"albums";;
static NSString * const SPTArtistJSONURIKey = @"uri";
static NSString * const SPTArtistJSONGenresKey = @"genres";
static NSString * const SPTArtistJSONImagesKey = @"images";
static NSString * const SPTArtistJSONPopularityKey = @"popularity";
static NSString * const SPTArtistJSONTopTracksTracksKey = @"tracks";
static NSString * const SPTArtistJSONRelatedArtistsArtistsKey = @"artists";
static NSString * const SPTArtistJSONExternalURLsKey = @"external_urls";
static NSString * const SPTArtistJSONExternalURLSpotifyKey = @"spotify";
static NSString * const SPTArtistJSONFollowersKey = @"followers";
static NSString * const SPTArtistJSONTotalKey = @"total";

@interface SPTArtist ()
@property (nonatomic, readwrite, copy) NSArray *albums;
@property (nonatomic, readwrite, copy) NSArray *genres;
@property (nonatomic, readwrite, copy) NSArray *images;
@property (nonatomic, readwrite) double popularity;
@property (nonatomic, readwrite) SPTImage *smallestImage;
@property (nonatomic, readwrite) SPTImage *largestImage;
@property (nonatomic, readwrite) long followerCount;
@end

@implementation SPTArtist








///----------------------------
/// @name API Request Factories
///----------------------------

+ (NSURLRequest *)createRequestForArtist:(NSURL *)uri
						 withAccessToken:(NSString *)accessToken
								   error:(NSError *__autoreleasing *)error {
	
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	NSString *albumId = uriComponents[2];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/artists/%@", albumId]];
	
	NSMutableDictionary *values = [NSMutableDictionary dictionary];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+ (NSURLRequest *)createRequestForArtists:(NSArray *)uris
						  withAccessToken:(NSString *)accessToken
									error:(NSError *__autoreleasing *)error {
	
	NSMutableArray *ids = [NSMutableArray array];
	for(int i=0; i<uris.count; i++) {
		NSURL *uri = [uris objectAtIndex:i];
		NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
		if (uriComponents.count == 3 &&
			[uriComponents[0] isEqualToString:@"spotify"] &&
			[uriComponents[1] isEqualToString:@"artist"]) {
			[ids addObject:uriComponents[2]];
		}
	}
	
	
	NSMutableDictionary *values = [NSMutableDictionary dictionary];
	[values setValue:[ids componentsJoinedByString:@","] forKey:@"ids"];
	NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/artists"];
	
	return [SPTRequest createRequestForURL:url
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+ (NSURLRequest*)createRequestForAlbumsByArtist:(NSURL*)artist
										 ofType:(SPTAlbumType)type
								withAccessToken:(NSString *)accessToken
										 market:(NSString *)market
										  error:(NSError **)error {
	
	NSString *identifier = [self identifierFromURI:artist];
	
	NSMutableDictionary *values = [NSMutableDictionary new];
	
	if (market != nil) {
		values[@"country"] = market;
	}
	
	NSString *typeString = @"album";
	if (type == SPTAlbumTypeSingle)
		typeString = @"single";
	if (type == SPTAlbumTypeCompilation)
		typeString = @"compilation";
	if (type == SPTAlbumTypeAppearsOn)
		typeString = @"appears_on";
	
	values[@"album_type"] = typeString;
	
	NSString *urlString = [NSString stringWithFormat:@"https://api.spotify.com/v1/artists/%@/albums", identifier];
	
	return [SPTRequest createRequestForURL:[NSURL URLWithString:urlString]
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+ (NSURLRequest*)createRequestForTopTracksForArtist:(NSURL *)artist
									withAccessToken:(NSString *)accessToken
											 market:(NSString *)market
											  error:(NSError **)error {
	NSString *identifier = [self identifierFromURI:artist];
	
	NSMutableDictionary *values = [NSMutableDictionary new];
	
	if (market != nil)
		values[@"country"] = market;
	
	NSString *urlString = [NSString stringWithFormat:@"https://api.spotify.com/v1/artists/%@/top-tracks", identifier];
	return [SPTRequest createRequestForURL:[NSURL URLWithString:urlString]
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+ (NSURLRequest*)createRequestForArtistsRelatedTo:(NSURL *)artist
								  withAccessToken:(NSString *)accessToken
											error:(NSError **)error {
	NSString *identifier = [self identifierFromURI:artist];
	NSString *urlString = [NSString stringWithFormat:@"https://api.spotify.com/v1/artists/%@/related-artists", identifier];
	return [SPTRequest createRequestForURL:[NSURL URLWithString:urlString]
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:nil
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:NO
									 error:error];
}








///---------------------------
/// @name API Response Parsers
///---------------------------

-(id)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error {
	self = [super initWithDecodedJSONObject:decodedObject error:error];
	if (self) {
		
		if ([decodedObject[SPTArtistJSONGenresKey] isKindOfClass:[NSArray class]]) {
			self.genres = decodedObject[SPTArtistJSONGenresKey];
		}
		
		if ([decodedObject[SPTArtistJSONPopularityKey] respondsToSelector:@selector(doubleValue)])
			self.popularity = [decodedObject[SPTArtistJSONPopularityKey] doubleValue];
		
		if (decodedObject[SPTArtistJSONFollowersKey] != nil &&
			decodedObject[SPTArtistJSONFollowersKey][SPTArtistJSONTotalKey] != nil) {
			if ([decodedObject[SPTArtistJSONFollowersKey][SPTArtistJSONTotalKey] respondsToSelector:@selector(longValue)])
				self.followerCount = [decodedObject[SPTArtistJSONFollowersKey][SPTArtistJSONTotalKey] longValue];
		}
		
		if ([decodedObject[SPTArtistJSONAlbumsKey] isKindOfClass:[NSArray class]]) {
			
			NSArray *albums = decodedObject[SPTArtistJSONAlbumsKey];
			NSMutableArray *decodedAlbums = [NSMutableArray arrayWithCapacity:albums.count];
			
			for (id obj in albums) {
				id decodedItem = [SPTJSONDecoding partialSPObjectFromDecodedJSON:obj[@"album"] error:error];
				if (decodedItem == nil) return nil;
				[decodedAlbums addObject:decodedItem];
			}
			
			self.albums	= decodedAlbums;
		}
		
		if ([decodedObject[SPTArtistJSONImagesKey] isKindOfClass:[NSArray class]]) {
			NSArray *decodedImages = decodedObject[SPTArtistJSONImagesKey];
			NSMutableArray *covers = [NSMutableArray arrayWithCapacity:decodedImages.count];
			for (id image in decodedImages) {
				if ([image isKindOfClass:[NSDictionary class]]) {
					SPTImage *cover = [[SPTImage alloc] initWithDecodedJSON:image];
					if (cover) [covers addObject:cover];
				}
			}
			
			[covers sortUsingComparator:^NSComparisonResult(SPTImage *obj1, SPTImage *obj2) {
				return obj1.size.width - obj2.size.width;
			}];
			
			self.images = [NSArray arrayWithArray:covers];
			self.smallestImage = covers.count > 0 ? covers[0] : nil;
			self.largestImage = [covers lastObject];
		}
		
	}
	return self;
}

+ (instancetype)artistFromData:(NSData *)data
				  withResponse:(NSURLResponse *)response
						 error:(NSError **)error {
	if (data == nil) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"data is nil"];
		}
		return nil;
	}

	id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
	if (error != nil && *error != nil) {
		return nil;
	}
	
	return [self artistFromDecodedJSON:decodedObj error:error];
}

+ (NSArray *)artistsFromData:(NSData *)data
				withResponse:(NSURLResponse *)response
					   error:(NSError **)error {
	
	if (data == nil) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"data is nil"];
		}
		return nil;
	}
	
	id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
	if (error != nil && *error != nil) {
		return nil;
	}
	
	return [SPTArtist artistsFromDecodedJSON:decodedObj error:error];
}

+ (instancetype)artistFromDecodedJSON:(id)decodedObject
								error:(NSError **)error {
	
	return [[SPTArtist alloc] initWithDecodedJSONObject:decodedObject error:error];
}

+ (NSArray *)artistsFromDecodedJSON:(id)decodedObject
							  error:(NSError **)error {
	
	if (decodedObject == nil) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"decodedObject is nil"];
		}
		return nil;
	}
	
	if (![decodedObject[@"artists"] isKindOfClass:[NSArray class]]) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"decodedObject does not contain an 'artists' array"];
		}
		return nil;
	}
	
	NSArray *jsonChildren = decodedObject[@"artists"];
	NSMutableArray *children = [NSMutableArray arrayWithCapacity:jsonChildren.count];
	for (id jsonChild in jsonChildren) {
		id decodedChild = [SPTArtist artistFromDecodedJSON:jsonChild error:error];
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




















///--------------------------
/// @name Convenience Methods
///--------------------------

+ (void)artistWithURI:(NSURL *)uri
		  accessToken:(NSString *)accessToken
			 callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForArtist:uri withAccessToken:accessToken error:&reqerr];
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *parseerr = nil;
		SPTArtist *artist = [SPTArtist artistFromData:data withResponse:response error:&parseerr];
		
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(parseerr);
		SP_DISPATCH_ASYNC_BLOCK_RESULT(artist);
	}];
}

+ (void)artistsWithURIs:(NSArray *)uris
			accessToken:(NSString *)accessToken
			   callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForArtists:uris withAccessToken:accessToken error:&reqerr];
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *jsonerr = nil;
		id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonerr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(jsonerr);
		
		NSError *parseerr = nil;
		NSArray *artists = [SPTArtist artistsFromDecodedJSON:jsonObj error:&parseerr];
		
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(parseerr);
		SP_DISPATCH_ASYNC_BLOCK_RESULT(artists);
	}];
}

- (void)requestAlbumsOfType:(SPTAlbumType)type
			withAccessToken:(NSString *)accessToken
	   availableInTerritory:(NSString *)territory
				   callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTArtist createRequestForAlbumsByArtist:self.uri ofType:type withAccessToken:accessToken market:territory error:&reqerr];
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *jsonerr = nil;
		id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonerr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(jsonerr);
		
		SPTListPage *newPage = [[SPTListPage alloc] initWithDecodedJSONObject:jsonObj
													 expectingPartialChildren:YES
																rootObjectKey:nil];
		
		SP_DISPATCH_ASYNC_BLOCK_RESULT(newPage);
	}];
}

- (void)requestTopTracksForTerritory:(NSString *)territory
					 withAccessToken:(NSString *)accessToken
							callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTArtist createRequestForTopTracksForArtist:self.uri withAccessToken:accessToken market:territory error:&reqerr];
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *decerr = nil;
		id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decerr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(decerr);
		
		NSError *loaderr = nil;
		NSArray *tracks = [SPTTrack tracksFromDecodedJSON:decodedObj error:&loaderr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(loaderr);
		
		SP_DISPATCH_ASYNC_BLOCK_RESULT(tracks);
	}];
}

- (void)requestRelatedArtistsWithAccessToken:(NSString *)accessToken
									callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTArtist createRequestForArtistsRelatedTo:self.uri withAccessToken:accessToken error:&reqerr];
	SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(reqerr);
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(error);
		
		NSError *decerr = nil;
		id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decerr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(decerr);
		
		NSError *loaderr = nil;
		NSArray *artists = [SPTArtist artistsFromDecodedJSON:decodedObj error:&loaderr];
		SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(loaderr);
		
		SP_DISPATCH_ASYNC_BLOCK_RESULT(artists);
	}];
}

///--------------------
/// @name Miscellaneous
///--------------------

+(void)load {
	[SPTJSONDecoding registerClass:self forJSONType:@"artist"];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@ (%@)", [super description], self.name, self.uri];
}

+(BOOL)isArtistURI:(NSURL*)uri {
	if (uri == nil)
		return NO;
	
	NSArray *uriComponents = [[uri absoluteString] componentsSeparatedByString:@":"];
	if (uriComponents.count != 3)
		return NO;
	
	if (![uriComponents[0] isEqualToString:@"spotify"])
		return NO;
	
	if (![uriComponents[1] isEqualToString:@"artist"])
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
	
	if (![uriComponents[1] isEqualToString:@"artist"])
		return nil;
	
	// TODO: validate base62
	
	return uriComponents[2];
}

@end
