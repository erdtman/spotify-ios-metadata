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

#import "SPTPlaylistTrack.h"
#import "SPTJSONDecoding.h"
#import "SPTJSONDecoding_Internal.h"

static NSString * const SPTPlaylistTrackJSONTrackKey = @"track";
static NSString * const SPTPlaylistTrackJSONAddedAtKey = @"added_at";
static NSString * const SPTPlaylistTrackJSONAddedByKey = @"added_by";

@interface SPTPlaylistTrack()
@property (nonatomic, readwrite, copy) NSDate *addedAt;
@property (nonatomic, readwrite) SPTUser *addedBy;
@end

@implementation SPTPlaylistTrack

+ (void)load {
	[SPTJSONDecoding registerPartialClass:self forJSONType:@"containedtrack"];
}

- (instancetype)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error
{
	self = [super initWithDecodedJSONObject:decodedObject[SPTPlaylistTrackJSONTrackKey] error:error];
	if (self) {
		if (decodedObject == nil) {
			return self;
		}

		if ([decodedObject isKindOfClass:[NSNull class]]) {
			return self;
		}

		if ([decodedObject[SPTPlaylistTrackJSONAddedAtKey] isKindOfClass:[NSString class]]) {
			
			if (decodedObject[SPTPlaylistTrackJSONAddedAtKey] != nil) {
				NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
				[formatter setDateFormat:@"YYYY'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
				self.addedAt = [formatter dateFromString:decodedObject [SPTPlaylistTrackJSONAddedAtKey]];
			}

			if ([decodedObject[SPTPlaylistTrackJSONAddedByKey] isKindOfClass:[NSDictionary class]]) {
				self.addedBy = [SPTJSONDecoding SPObjectFromDecodedJSON:decodedObject[SPTPlaylistTrackJSONAddedByKey] error:nil];
			}
		}
	}
	return self;
}

@end
