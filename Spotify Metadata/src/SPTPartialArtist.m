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

#import "SPTPartialArtist.h"
#import "SPTJSONDecoding_Internal.h"

static NSString * const SPTPartialArtistJSONIDKey = @"id";
static NSString * const SPTPartialArtistJSONNameKey = @"name";
static NSString * const SPTPartialArtistJSONURIKey = @"uri";
static NSString * const SPTPartialArtistJSONExternalURLsKey = @"external_urls";
static NSString * const SPTPartialArtistJSONExternalURLSpotifyKey = @"spotify";

@interface SPTPartialArtist ()
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, copy) NSURL *uri;
@property (nonatomic, readwrite, copy) NSString *identifier;
@property (nonatomic, readwrite, copy) NSURL *sharingURL;

@end

@implementation SPTPartialArtist

+(void)load {
	[SPTJSONDecoding registerPartialClass:self forJSONType:@"artist"];
}

+ (instancetype)partialArtistFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	return [[SPTPartialArtist alloc] initWithDecodedJSONObject:decodedObject error:error];
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
		
		if (decodedObject[SPTPartialArtistJSONIDKey] != nil) {
			self.identifier = [NSString stringWithFormat:@"%@", decodedObject[SPTPartialArtistJSONIDKey]];
		}
		
		if (decodedObject[SPTPartialArtistJSONNameKey] != nil) {
			self.name = [NSString stringWithFormat:@"%@", decodedObject[SPTPartialArtistJSONNameKey]];
		}
		
		if (decodedObject[SPTPartialArtistJSONURIKey] != nil) {
			self.uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialArtistJSONURIKey]]];
		}
		
		if ([decodedObject[SPTPartialArtistJSONExternalURLsKey] isKindOfClass:[NSDictionary class]] &&
			decodedObject[SPTPartialArtistJSONExternalURLsKey][SPTPartialArtistJSONExternalURLSpotifyKey] != nil) {
			self.sharingURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTPartialArtistJSONExternalURLsKey][SPTPartialArtistJSONExternalURLSpotifyKey]]];
		}
	}
	
	return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@ (%@)", [super description], self.name, self.uri];
}

@end
