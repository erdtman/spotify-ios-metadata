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

#import "SPTImage.h"

static NSString * const SPTAlbumCoverJSONImageURLKey = @"url";
static NSString * const SPTAlbumCoverJSONImageHeightKey = @"height";
static NSString * const SPTAlbumCoverJSONImageWidthKey = @"width";

@interface SPTImage ()

@property (nonatomic, readwrite) CGSize size;
@property (nonatomic, readwrite, copy) NSURL *imageURL;

@end

@implementation SPTImage

+ (instancetype)imageFromDecodedJSON:(id)decodedObject error:(NSError *__autoreleasing *)error {
	return [[SPTImage alloc] initWithDecodedJSON:decodedObject];
}

-(id)initWithDecodedJSON:(id)json {
	self = [super init];
	if (self) {
		if (json == nil) {
			return self;
		}
		
		if ([json isKindOfClass:[NSNull class]]) {
			return self;
		}
		
		if (json[SPTAlbumCoverJSONImageURLKey] != nil) {
			self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", json[SPTAlbumCoverJSONImageURLKey]]];
		}
		
		CGSize size = CGSizeZero;
		
		if ([json[SPTAlbumCoverJSONImageHeightKey] respondsToSelector:@selector(doubleValue)]) {
			size.height = [json[SPTAlbumCoverJSONImageHeightKey] doubleValue];
		}
		
		if ([json[SPTAlbumCoverJSONImageWidthKey] respondsToSelector:@selector(doubleValue)]) {
			size.width = [json[SPTAlbumCoverJSONImageWidthKey] doubleValue];
		}
		
		self.size = size;
		
	}
	return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: Image (%@x%@px)", [super description], @(self.size.width), @(self.size.height)];
}

@end
