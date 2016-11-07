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

#import "SPTPartialTrack.h"
#import "SPTPartialAlbum.h"
#import "SPTJSONDecoding_Internal.h"

static NSString * const SPTPartialTrackJSONIdKey = @"id";
static NSString * const SPTPartialTrackJSONNameKey = @"name";
static NSString * const SPTPartialTrackJSONURIKey = @"uri";
static NSString * const SPTPartialTrackJSONArtistsKey = @"artists";
static NSString * const SPTPartialTrackJSONAlbumKey = @"album";
static NSString * const SPTPartialTrackJSONDurationKey = @"duration_ms";
static NSString * const SPTPartialTrackJSONExternalURLSpotifyKey = @"spotify";
static NSString * const SPTPartialTrackJSONDiscNumberKey = @"disc_number";
static NSString * const SPTPartialTrackJSONTrackNumberKey = @"track_number";
static NSString * const SPTPartialTrackJSONExplicitKey = @"explicit";
static NSString * const SPTPartialTrackJSONExternalIDsKey = @"external_ids";
static NSString * const SPTPartialTrackJSONPreviewURLKey = @"preview_url";
static NSString * const SPTPartialTrackJSONAvailableMarketsKey = @"available_markets";
static NSString * const SPTPartialTrackJSONExternalURLsKey = @"external_urls";
static NSString * const SPTPartialTrackJSONPlayableKey = @"is_playable";

@interface SPTPartialTrack ()
@property (nonatomic, readwrite, copy) NSString *identifier;
@property (nonatomic, readwrite, copy) NSURL *uri;
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic, readwrite, copy) NSURL *sharingURL;
@property (nonatomic, readwrite, copy) NSURL *previewURL;
@property (nonatomic, readwrite, copy) NSArray *artists;
@property (nonatomic, readwrite) NSInteger trackNumber;
@property (nonatomic, readwrite) NSInteger discNumber;
@property (nonatomic, readwrite) BOOL flaggedExplicit;
@property (nonatomic, readwrite) BOOL isPlayable;
@property (nonatomic, readwrite) BOOL hasPlayable;
@property (nonatomic, readwrite, copy) NSArray *availableTerritories;
@property (nonatomic, readwrite, copy) NSURL *playableUri;
@property (nonatomic, readwrite, strong) SPTPartialAlbum *album;
@end

@implementation SPTPartialTrack

+ (void)load {
	[SPTJSONDecoding registerPartialClass:self forJSONType:@"track"];
}

+ (instancetype)partialTrackFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	return [[SPTPartialTrack alloc] initWithDecodedJSONObject:decodedObject error:error];
}

- (id)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error {
	self = [super initWithDecodedJSONObject:decodedObject error:error];
	if (self) {
		if (decodedObject == nil) {
			return self;
		}
		
		if ([decodedObject isKindOfClass:[NSNull class]]) {
			return self;
		}
		
		if ([decodedObject[SPTPartialTrackJSONIdKey] isKindOfClass:[NSString class]]) {
			self.identifier = [NSString stringWithFormat:@"%@", decodedObject[SPTPartialTrackJSONIdKey]];
		}
		
		if (self.identifier != nil) {
			self.playableUri = [NSURL URLWithString:[NSString stringWithFormat:@"spotify:track:%@", self.identifier]];
		}
		
		self.hasPlayable = NO;
		self.isPlayable = YES;
		if ([decodedObject[SPTPartialTrackJSONPlayableKey] respondsToSelector:@selector(boolValue)]) {
			self.hasPlayable = YES;
			self.isPlayable = [decodedObject[SPTPartialTrackJSONPlayableKey] boolValue];
		}
				
		if ([decodedObject[SPTPartialTrackJSONNameKey] isKindOfClass:[NSString class]]) {
			self.name = [NSString stringWithFormat:@"%@", decodedObject[SPTPartialTrackJSONNameKey]];
		}
		
		if ([decodedObject[SPTPartialTrackJSONURIKey] isKindOfClass:[NSString class]]) {
			self.uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialTrackJSONURIKey]]];
		}
		
		if ([decodedObject[SPTPartialTrackJSONDurationKey] respondsToSelector:@selector(doubleValue)]) {
			self.duration = [decodedObject[SPTPartialTrackJSONDurationKey] doubleValue] / 1000.0;
		}
		
		if ([decodedObject[SPTPartialTrackJSONExplicitKey] respondsToSelector:@selector(boolValue)]) {
			self.flaggedExplicit = [decodedObject[SPTPartialTrackJSONExplicitKey] boolValue];
		}
		
		if ([decodedObject[SPTPartialTrackJSONAvailableMarketsKey] isKindOfClass:[NSArray class]]) {
			self.availableTerritories = decodedObject[SPTPartialTrackJSONAvailableMarketsKey];
		}
		
		if ([decodedObject[SPTPartialTrackJSONExternalURLsKey] isKindOfClass:[NSDictionary class]] &&
			decodedObject[SPTPartialTrackJSONExternalURLsKey][SPTPartialTrackJSONExternalURLSpotifyKey] != nil) {
			self.sharingURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialTrackJSONExternalURLsKey][SPTPartialTrackJSONExternalURLSpotifyKey]]];
		}
		
		if (decodedObject[SPTPartialTrackJSONPreviewURLKey] != nil) {
			self.previewURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialTrackJSONPreviewURLKey]]];
		}
		
		if ([decodedObject[SPTPartialTrackJSONTrackNumberKey] respondsToSelector:@selector(integerValue)]) {
			self.trackNumber = [decodedObject[SPTPartialTrackJSONTrackNumberKey] integerValue];
		}
		
		if ([decodedObject[SPTPartialTrackJSONDiscNumberKey] respondsToSelector:@selector(integerValue)]) {
			self.discNumber = [decodedObject[SPTPartialTrackJSONDiscNumberKey] integerValue];
		}
		
		if ([decodedObject[SPTPartialTrackJSONAvailableMarketsKey] isKindOfClass:[NSArray class]]) {
			self.availableTerritories = decodedObject[SPTPartialTrackJSONAvailableMarketsKey];
		}
		
		if ([decodedObject[SPTPartialTrackJSONArtistsKey] isKindOfClass:[NSArray class]]) {
			NSArray *artists = decodedObject[SPTPartialTrackJSONArtistsKey];
			NSMutableArray *decodedArtists = [NSMutableArray arrayWithCapacity:artists.count];
			
			for (id obj in artists) {
				id decodedItem = [SPTJSONDecoding partialSPObjectFromDecodedJSON:obj error:error];
				if (decodedItem == nil) return nil;
				[decodedArtists addObject:decodedItem];
			}
			
			self.artists = decodedArtists;
		}
		
		
		if (decodedObject[SPTPartialTrackJSONAlbumKey] != nil) {
			id decodedAlbum = [SPTJSONDecoding partialSPObjectFromDecodedJSON:decodedObject[SPTPartialTrackJSONAlbumKey] error:error];
			if (decodedAlbum == nil) return nil;
			self.album = decodedAlbum;
		}
		
	}
	
	return self;
}

- (NSArray *) tracksForPlayback {
	return @[self];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@: %@ (%@)", [super description], self.name, self.uri];
}

@end
