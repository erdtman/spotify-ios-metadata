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

#import "SPTListPage.h"
#import "SPTListPage_Internal.h"
#import "SPTFeaturedPlaylistList.h"
#import "SPTRequest_Internal.h"

static NSString * const SPTFeaturedPlaylistListJSONMessageKey = @"message";

@interface SPTFeaturedPlaylistList ()

@property (nonatomic, readwrite) NSString *message;

@end

@implementation SPTFeaturedPlaylistList

-(id)initWithDecodedJSONObject:(id)jsonObj error:(NSError **)error {
	return [self initWithDecodedJSONObject:jsonObj];
}

-(id)initWithDecodedJSONObject:(id)jsonObj {
	self = [super initWithDecodedJSONObject:jsonObj expectingPartialChildren:YES rootObjectKey:@"playlists"];
	if (self) {
		if (jsonObj == nil) {
			return self;
		}

		if ([jsonObj isKindOfClass:[NSNull class]]) {
			return self;
		}

		if ([jsonObj[SPTFeaturedPlaylistListJSONMessageKey] isKindOfClass:[NSString class]] &&
			((NSString *)jsonObj[SPTFeaturedPlaylistListJSONMessageKey]).length > 0)
			self.message = jsonObj[SPTFeaturedPlaylistListJSONMessageKey];
		
	}
	return self;
}

+ (instancetype)featuredPlaylistListFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	if (decodedObject == nil) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"Input is nil."];
		}
		return nil;
	}
	
	if ([decodedObject isKindOfClass:[NSNull class]]) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"JSON root element is null."];
		}
		return nil;
	}

	SPTFeaturedPlaylistList *list = [SPTFeaturedPlaylistList alloc];
	list = [list initWithDecodedJSONObject:decodedObject];
	return list;
}

+ (instancetype)featuredPlaylistListFromData:(NSData *)data withResponse:(NSURLResponse*)response error:(NSError **)error {
	if (data == nil) {
		if (error != nil) {
			*error = [SPTRequest createError:401 withDescription:@"Input is nil."];
		}
		return nil;
	}

	NSError *err = nil;
	id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
	
	if (err != nil) {
		if (error != nil) {
			*error = err;
		}
		return nil;
	}
		
	SPTFeaturedPlaylistList *page = [[SPTFeaturedPlaylistList alloc] initWithDecodedJSONObject:json];
	return page;
}

@end
