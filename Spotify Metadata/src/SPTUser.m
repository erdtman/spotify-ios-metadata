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

#import "SPTUser.h"
#import "SPTImage.h"
#import "SPTImage_Internal.h"
#import "SPTJSONDecoding_Internal.h"
#import "SPTRequest.h"
#import "SPTRequest_Internal.h"

static NSString * const SPTUserJSONURIKey = @"uri";
static NSString * const SPTUserJSONProductKey = @"product";
static NSString * const SPTUserJSONImagesKey = @"images";
static NSString * const SPTUserJSONExternalURLsKey = @"external_urls";
static NSString * const SPTUserJSONExternalURLSpotifyKey = @"spotify";
static NSString * const SPTUserJSONEmailKey = @"email";
static NSString * const SPTUserJSONDisplayNameKey = @"display_name";
static NSString * const SPTUserJSONIdKey = @"id";
static NSString * const SPTUserJSONCountryKey = @"country";
static NSString * const SPTUserJSONFollowersKey = @"followers";
static NSString * const SPTUserJSONTotalKey = @"total";


@interface SPTUser ()
@property (nonatomic, readwrite, copy) NSString *displayName;
@property (nonatomic, readwrite, copy) NSString *canonicalUserName;
@property (nonatomic, readwrite, copy) NSString *territory;
@property (nonatomic, readwrite, copy) NSString *emailAddress;
@property (nonatomic, readwrite, copy) NSURL *uri;
@property (nonatomic, readwrite, copy) NSURL *sharingURL;
@property (nonatomic, readwrite, copy) NSArray *images;
@property (nonatomic, readwrite) SPTImage *smallestImage;
@property (nonatomic, readwrite) SPTImage *largestImage;
@property (nonatomic, readwrite) SPTProduct product;
@property (nonatomic, readwrite) long followerCount;
@end

@implementation SPTUser

+(void)load {
	[SPTJSONDecoding registerClass:self forJSONType:@"user"];
}


-(id)initWithDecodedJSONObject:(id)decodedObject error:(NSError **)error {
	self = [super initWithDecodedJSONObject:decodedObject error:error];
	if (self) {

		self.product = SPTProductUnknown;
		if ([decodedObject[SPTUserJSONProductKey] isKindOfClass:[NSString class]]) {

			NSString *productString = decodedObject[SPTUserJSONProductKey];
			if ([productString caseInsensitiveCompare:@"premium"] == NSOrderedSame) {
				self.product = SPTProductPremium;
			} else if ([productString caseInsensitiveCompare:@"unlimited"] == NSOrderedSame) {
				self.product = SPTProductUnlimited;
			} else if ([productString caseInsensitiveCompare:@"free"] == NSOrderedSame) {
				self.product = SPTProductFree;
			}
		}

		if ([decodedObject[SPTUserJSONDisplayNameKey] isKindOfClass:[NSString class]])
			self.displayName = [NSString stringWithFormat:@"%@", decodedObject[SPTUserJSONDisplayNameKey]];

		if ([decodedObject[SPTUserJSONIdKey] isKindOfClass:[NSString class]])
			self.canonicalUserName = [NSString stringWithFormat:@"%@", decodedObject[SPTUserJSONIdKey]];

		if ([decodedObject[SPTUserJSONCountryKey] isKindOfClass:[NSString class]])
			self.territory = [NSString stringWithFormat:@"%@", decodedObject[SPTUserJSONCountryKey]];

		if ([decodedObject[SPTUserJSONEmailKey] isKindOfClass:[NSString class]])
			self.emailAddress = [NSString stringWithFormat:@"%@", decodedObject[SPTUserJSONEmailKey]];

		if ([decodedObject[SPTUserJSONURIKey] isKindOfClass:[NSString class]])
			self.uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTUserJSONURIKey]]];

		if ([decodedObject[SPTUserJSONExternalURLsKey] isKindOfClass:[NSDictionary class]] &&
			decodedObject[SPTUserJSONExternalURLsKey][SPTUserJSONExternalURLSpotifyKey] != nil)
			self.sharingURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", decodedObject[SPTUserJSONExternalURLsKey][SPTUserJSONExternalURLSpotifyKey]]];

		if ([decodedObject[SPTUserJSONImagesKey] isKindOfClass:[NSArray class]]) {
			NSArray *decodedImages = decodedObject[SPTUserJSONImagesKey];
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
		
		if (decodedObject[SPTUserJSONFollowersKey] != nil &&
			decodedObject[SPTUserJSONFollowersKey][SPTUserJSONTotalKey] != nil) {
			if ([decodedObject[SPTUserJSONFollowersKey][SPTUserJSONTotalKey] respondsToSelector:@selector(longValue)])
				self.followerCount = [decodedObject[SPTUserJSONFollowersKey][SPTUserJSONTotalKey] longValue];
		}
		

	}
	return self;
	
	
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@", [super description], self.canonicalUserName];
}

+ (NSURLRequest *)createRequestForCurrentUserWithAccessToken:(NSString *)accessToken error:(NSError **)error {
	NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/me"];
	return [SPTRequest createRequestForURL:url withAccessToken:accessToken httpMethod:@"GET" values:nil error:error];
}

+ (NSURLRequest *)createRequestForUser:(NSString *)username withAccessToken:(NSString *)accessToken error:(NSError **)error {
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@", [SPTRequest urlEncodeString:username]]];
	return [SPTRequest createRequestForURL:url withAccessToken:accessToken httpMethod:@"GET" values:nil error:error];
}

+ (instancetype)userFromDecodedJSON:(id)decodedObject error:(NSError **)error {
	return [[SPTUser alloc] initWithDecodedJSONObject:decodedObject error:error];
}

+ (SPTUser *)userFromData:(NSData *)data withResponse:(NSURLResponse *)response error:(NSError **)error {
	NSError *err = nil;

	id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
	if (err != nil) {
		*error = err;
		return nil;
	}
	
	id obj = [SPTJSONDecoding SPObjectFromDecodedJSON:json error:&err];
	if (err != nil) {
		*error = err;
		return nil;
	}
	
	return obj;
}

+(void)requestCurrentUserWithAccessToken:(NSString *)accessToken callback:(SPTRequestCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForCurrentUserWithAccessToken:accessToken error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}

	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		
		if (error != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error, nil); });
			return;
		}
		
		NSError *resperr = nil;
		SPTUser *user = [self userFromData:data withResponse:response error:&resperr];
		if (resperr != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(resperr, nil); });
			return;
		}
		
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, user); });
	}];
}

+(void)requestUser:(NSString *)username withAccessToken:(NSString *)accessToken callback:(SPTRequestCallback)block {
	NSError *reqerr = nil;
	NSURLRequest *req = [self createRequestForUser:username withAccessToken:accessToken error:&reqerr];
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		
		if (error != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(error, nil); });
			return;
		}
		
		NSError *resperr = nil;
		SPTUser *user = [self userFromData:data withResponse:response error:&resperr];
		if (resperr != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(resperr, nil); });
			return;
		}
		
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, user); });
	}];
}

@end
