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

#import "SPTJSONDecoding.h"
#import "SPTJSONDecoding_Internal.h"

static NSString * const SPJSONObjectTypeKey = @"type";
static NSString * const SPJSONPlaylistTrackDateAddedKey = @"added_at";

@implementation SPTJSONDecoding

#pragma mark - Registration and Predicates

static NSMutableDictionary *types;
static NSMutableDictionary *partialTypes;

+(void)initialize {
	types = [NSMutableDictionary new];
	partialTypes = [NSMutableDictionary new];
}

+(void)registerClass:(Class)aClass forJSONType:(NSString *)type {
	types[type] = aClass;
}

+(void)registerPartialClass:(Class)aClass forJSONType:(NSString *)type {
	partialTypes[type] = aClass;
}

#pragma mark - Decoding

+(id)SPObjectFromEncodedJSON:(NSData *)json error:(NSError **)error {
	return [self SPObjectFromEncodedJSON:json collection:types error:error];
}

+(id)SPObjectFromDecodedJSON:(id)decodedJson error:(NSError **)error {
	return [self SPObjectFromDecodedJSON:decodedJson collection:types error:error];
}

+(id)partialSPObjectFromEncodedJSON:(NSData *)json error:(NSError **)error {
	return [self SPObjectFromEncodedJSON:json collection:partialTypes error:error];
}

+(id)partialSPObjectFromDecodedJSON:(id)decodedJson error:(NSError **)error {
	return [self SPObjectFromDecodedJSON:decodedJson collection:partialTypes error:error];
}

// ----

+(id)SPObjectFromEncodedJSON:(NSData *)json collection:(NSDictionary *)classCollection error:(NSError **)error {

	id decodedObj = [NSJSONSerialization JSONObjectWithData:json options:0 error:error];

	if (decodedObj == nil) {
		if (error != NULL) *error = [NSError errorWithDomain:@"com.spotify.ios-sdk" code:100 userInfo:@{NSLocalizedDescriptionKey : @"Invalid JSON"}];
		return nil;
	}

	return [self SPObjectFromDecodedJSON:decodedObj collection:classCollection error:error];
}

+(id)SPObjectFromDecodedJSON:(id)decodedJson collection:(NSDictionary *)classCollection error:(NSError **)error {

	NSString *typeString = decodedJson[SPJSONObjectTypeKey];
	BOOL isPlaylistTrack = decodedJson[SPJSONPlaylistTrackDateAddedKey] != nil;

	if (isPlaylistTrack && typeString == nil) {
		typeString = @"containedtrack";
	}

	if (typeString.length == 0) {
		if (error != NULL) *error = [NSError errorWithDomain:@"com.spotify.ios-sdk" code:101 userInfo:@{NSLocalizedDescriptionKey : @"JSON object contains no type"}];
		return nil;
	}

	Class objClass = classCollection[typeString];
	if ([objClass conformsToProtocol:@protocol(SPTJSONObject)])
		return [(id <SPTJSONObject>)[objClass alloc] initWithDecodedJSONObject:decodedJson error:error];


	NSString *errorString = [NSString stringWithFormat:@"No registered class for type '%@'", typeString];
	if (error != NULL) *error = [NSError errorWithDomain:@"com.spotify.ios-sdk" code:102 userInfo:@{NSLocalizedDescriptionKey : errorString}];
	return nil;
}

@end

@implementation SPTJSONObjectBase 

-(id)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error {
	self = [super init];
	
	if (self) {
		self.decodedJSONObject = decodedObject;
	}
	
	return self;
}

@end
