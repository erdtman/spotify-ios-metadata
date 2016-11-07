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

#import "SPTPartialAlbum.h"
#import "SPTJSONDecoding_Internal.h"
#import "SPTImage.h"
#import "SPTImage_Internal.h"

static NSString * const SPTPartialAlbumJSONNameKey = @"name";
static NSString * const SPTPartialAlbumJSONURIKey = @"uri";
static NSString * const SPTPartialAlbumJSONIDKey = @"id";
static NSString * const SPTPartialAlbumJSONImagesKey = @"images";
static NSString * const SPTPartialAlbumJSONAlbumTypeKey = @"album_type";
static NSString * const SPTPartialAlbumJSONAvailableMarketsKey = @"available_markets";
static NSString * const SPTPartialAlbumJSONExternalURLsKey = @"external_urls";
static NSString * const SPTPartialAlbumJSONExternalURLSpotifyKey = @"spotify";

@interface SPTPartialAlbum ()
@property (nonatomic, readwrite, copy) NSString *identifier;
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, copy) NSURL *uri;
@property (nonatomic, readwrite, copy) NSArray *covers;
@property (nonatomic, readwrite) SPTImage *smallestCover;
@property (nonatomic, readwrite) SPTImage *largestCover;
@property (nonatomic, readwrite) SPTAlbumType type;
@property (nonatomic, readwrite, copy) NSURL *playableUri;
@property (nonatomic, readwrite, copy) NSURL *sharingURL;
@property (nonatomic, readwrite, copy) NSArray *availableTerritories;

@end

@implementation SPTPartialAlbum

+(void)load {
	[SPTJSONDecoding registerPartialClass:self forJSONType:@"album"];
}

+ (instancetype)partialAlbumFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	return [[SPTPartialAlbum alloc] initWithDecodedJSONObject:decodedObject error:error];
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
		
		if (decodedObject[SPTPartialAlbumJSONIDKey] != nil) {
			self.identifier = [NSString stringWithFormat:@"%@", decodedObject[SPTPartialAlbumJSONIDKey]];
		}

		if (decodedObject[SPTPartialAlbumJSONNameKey] != nil) {
			self.name = [NSString stringWithFormat:@"%@", decodedObject[SPTPartialAlbumJSONNameKey]];
		}
		
		if (decodedObject[SPTPartialAlbumJSONURIKey] != nil) {
			self.uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialAlbumJSONURIKey]]];
			self.playableUri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialAlbumJSONURIKey]]];
		}
		
		if ([decodedObject[SPTPartialAlbumJSONExternalURLsKey] isKindOfClass:[NSDictionary class]] &&
			decodedObject[SPTPartialAlbumJSONExternalURLsKey][SPTPartialAlbumJSONExternalURLSpotifyKey] != nil) {
			self.sharingURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialAlbumJSONExternalURLsKey][SPTPartialAlbumJSONExternalURLSpotifyKey]]];
		}
		
		if (decodedObject[SPTPartialAlbumJSONNameKey] != nil) {
			self.name = [NSString stringWithFormat:@"%@", decodedObject[SPTPartialAlbumJSONNameKey]];
		}
		
		if (decodedObject[SPTPartialAlbumJSONURIKey] != nil) {
			self.uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialAlbumJSONURIKey]]];
		}
		
		if ([decodedObject[SPTPartialAlbumJSONAvailableMarketsKey] isKindOfClass:[NSArray class]]) {
			self.availableTerritories = decodedObject[SPTPartialAlbumJSONAvailableMarketsKey];
		}
		
		if ([decodedObject[SPTPartialAlbumJSONAlbumTypeKey] isKindOfClass:[NSString class]]) {
			NSString *jsonTypeValue = decodedObject[SPTPartialAlbumJSONAlbumTypeKey];
			if ([jsonTypeValue caseInsensitiveCompare:@"APPEARS_ON"] == NSOrderedSame) {
				self.type = SPTAlbumTypeAppearsOn;
			} else if ([jsonTypeValue caseInsensitiveCompare:@"COMPILATION"] == NSOrderedSame) {
				self.type = SPTAlbumTypeCompilation;
			} else if ([jsonTypeValue caseInsensitiveCompare:@"SINGLE"] == NSOrderedSame) {
				self.type = SPTAlbumTypeSingle;
			} else {
				self.type = SPTAlbumTypeAlbum;
			}
		}
		
		if ([decodedObject[SPTPartialAlbumJSONImagesKey] isKindOfClass:[NSArray class]]) {
			NSArray *decodedImages = decodedObject[SPTPartialAlbumJSONImagesKey];
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
			
			self.covers = [NSArray arrayWithArray:covers];
			self.smallestCover = covers.count > 0 ? covers[0] : nil;
			self.largestCover = [covers lastObject];
		}
	}
	
	return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@ (%@)", [super description], self.name, self.uri];
}

@end
