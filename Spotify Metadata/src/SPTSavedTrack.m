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

#import "SPTSavedTrack.h"
#import "SPTJSONDecoding.h"
#import "SPTJSONDecoding_Internal.h"

static NSString * const SPTSavedTrackJSONTrackKey = @"track";
static NSString * const SPTPlaylistTrackJSONAddedAtKey = @"added_at";

@interface SPTSavedTrack()
@property (nonatomic, readwrite, copy) id decodedJSONObject;
@property (nonatomic, readwrite, copy) NSDate *addedAt;
@end

@implementation SPTSavedTrack

+(void)load {
	[SPTJSONDecoding registerClass:self forJSONType:@"containedtrack"];
}

@synthesize decodedJSONObject;

-(id)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error {
	self = [super initWithDecodedJSONObject:decodedObject[SPTSavedTrackJSONTrackKey] error:error];

	if (self) {
		if (decodedObject == nil) {
			return self;
		}

		if ([decodedObject isKindOfClass:[NSNull class]]) {
			return self;
		}

		self.decodedJSONObject = decodedObject;

		if (decodedObject[SPTPlaylistTrackJSONAddedAtKey] != nil) {
			NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"YYYY'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
			self.addedAt = [formatter dateFromString:decodedObject [SPTPlaylistTrackJSONAddedAtKey]];
		}
	}
	return self;
}

@end
