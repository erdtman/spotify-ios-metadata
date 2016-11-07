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

#import "SPTPartialPlaylist.h"
#import "SPTJSONDecoding_Internal.h"
#import "SPTUser.h"
#import "SPTImage_Internal.h"

static NSString * const SPTPlaylistJSONCollaborativeKey = @"collaborative";
static NSString * const SPTPlaylistJSONPublicKey = @"public";
static NSString * const SPTPlaylistJSONOwnerKey = @"owner";
static NSString * const SPTPlaylistJSONNameKey = @"name";
static NSString * const SPTPlaylistJSONURIKey = @"uri";
static NSString * const SPTPlaylistJSONTracksKey = @"tracks";
static NSString * const SPTPlaylistJSONTracksTotalKey = @"total";
static NSString * const SPTPlaylistJSONImagesKey = @"images";

@interface SPTPartialPlaylist ()
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, copy) NSURL *uri;
@property (nonatomic, readwrite, copy) NSURL *playableUri;
@property (nonatomic, readwrite) BOOL isCollaborative;
@property (nonatomic, readwrite) BOOL isPublic;
@property (nonatomic, readwrite) SPTUser *owner;
@property (nonatomic, readwrite) NSUInteger trackCount;
@property (nonatomic, readwrite, copy) NSArray *images;
@property (nonatomic, readwrite) SPTImage *smallestImage;
@property (nonatomic, readwrite) SPTImage *largestImage;
@end

@implementation SPTPartialPlaylist

+(void)load {
	[SPTJSONDecoding registerPartialClass:self forJSONType:@"playlist"];
}

-(id)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error {
	self = [super initWithDecodedJSONObject:decodedObject error:error];
	if (self) {
		// We're given an object from JSON, so be extra careful when decoding stuff.
		if (decodedObject == nil) {
			return self;
		}
		
		if ([decodedObject isKindOfClass:[NSNull class]]) {
			return self;
		}
		
		if ([decodedObject[SPTPlaylistJSONCollaborativeKey] respondsToSelector:@selector(boolValue)]) {
			self.isCollaborative = [decodedObject[SPTPlaylistJSONCollaborativeKey] boolValue];
		}

		if ([decodedObject[SPTPlaylistJSONOwnerKey] isKindOfClass:[NSDictionary class]]) {
			self.owner = [SPTJSONDecoding SPObjectFromDecodedJSON:decodedObject[SPTPlaylistJSONOwnerKey] error:nil];
		}
		
		if ([decodedObject[SPTPlaylistJSONNameKey] isKindOfClass:[NSString class]]) {
			self.name = [NSString stringWithFormat:@"%@", decodedObject[SPTPlaylistJSONNameKey]];
		}
		
		if ([decodedObject[SPTPlaylistJSONURIKey] isKindOfClass:[NSString class]]) {
			self.uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPlaylistJSONURIKey]]];
			self.playableUri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPlaylistJSONURIKey]]];
		}
		
		if ([decodedObject[SPTPlaylistJSONPublicKey] respondsToSelector:@selector(boolValue)]) {
			self.isPublic = [decodedObject[SPTPlaylistJSONPublicKey] boolValue];
		}
		
		if ([decodedObject[SPTPlaylistJSONTracksKey] isKindOfClass:[NSDictionary class]] &&
			[decodedObject[SPTPlaylistJSONTracksKey][SPTPlaylistJSONTracksTotalKey] respondsToSelector:@selector(integerValue)]) {
			self.trackCount = [decodedObject[SPTPlaylistJSONTracksKey][SPTPlaylistJSONTracksTotalKey] integerValue];
		}
		
		if ([decodedObject[SPTPlaylistJSONImagesKey] isKindOfClass:[NSArray class]]) {
			NSArray *decodedImages = decodedObject[SPTPlaylistJSONImagesKey];
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

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@ [%@ tracks] (%@)", [super description], self.name, @(self.trackCount), self.uri];
}

- (NSArray *)tracksForPlayback {
	return nil;
}

+ (instancetype)partialPlaylistFromDecodedJSON:(id)decodedObject
										 error:(NSError **)error {
	return [[SPTPartialPlaylist alloc] initWithDecodedJSONObject:decodedObject error:error];
}

@end
