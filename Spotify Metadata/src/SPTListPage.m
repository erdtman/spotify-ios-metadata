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
#import "SPTJSONDecoding.h"
#import "SPTRequest_Internal.h"

static NSString * const SPTListPageJSONItemsKey = @"items";
static NSString * const SPTListPageJSONHREFKey = @"href";
static NSString * const SPTListPageJSONLimitKey = @"limit";
static NSString * const SPTListPageJSONNextURLKey = @"next";
static NSString * const SPTListPageJSONOffsetKey = @"offset";
static NSString * const SPTListPageJSONPreviousURLKey = @"previous";
static NSString * const SPTListPageJSONTotalKey = @"total";

@interface SPTListPage ()

@property (nonatomic, readwrite) NSRange range;
@property (nonatomic, readwrite) NSUInteger totalListLength;
@property (nonatomic, readwrite, copy) NSArray *items;
@property (nonatomic, readwrite) BOOL hasPartialChildren;
@property (nonatomic, readwrite, copy) NSString *rootObjectKey;

@property (nonatomic, readwrite, copy) NSURL *nextPageURL;
@property (nonatomic, readwrite, copy) NSURL *previousPageURL;

@end

@implementation SPTListPage

-(id)initWithDecodedJSONObject:(id)jsonObj expectingPartialChildren:(BOOL)partialChildren rootObjectKey:(NSString *)rootKey {

	self = [super init];
	if (self) {
		id pageObject = jsonObj;
		if (rootKey.length > 0) {
			pageObject = jsonObj[rootKey];
		}

		self.rootObjectKey = rootKey;
		self.hasPartialChildren = partialChildren;

		if ([pageObject[SPTListPageJSONNextURLKey] isKindOfClass:[NSString class]] &&
			((NSString *)pageObject[SPTListPageJSONNextURLKey]).length > 0)
			self.nextPageURL = [NSURL URLWithString:pageObject[SPTListPageJSONNextURLKey]];

		if ([pageObject[SPTListPageJSONPreviousURLKey] isKindOfClass:[NSString class]] &&
			((NSString *)pageObject[SPTListPageJSONPreviousURLKey]).length > 0)
			self.previousPageURL = [NSURL URLWithString:pageObject[SPTListPageJSONPreviousURLKey]];

		if ([pageObject[SPTListPageJSONTotalKey] respondsToSelector:@selector(integerValue)])
			self.totalListLength = [pageObject[SPTListPageJSONTotalKey] integerValue];

		if ([pageObject[SPTListPageJSONItemsKey] isKindOfClass:[NSArray class]]) {

			NSArray *jsonChildren = pageObject[SPTListPageJSONItemsKey];
			NSMutableArray *children = [NSMutableArray arrayWithCapacity:jsonChildren.count];

			for (id jsonChild in jsonChildren) {

				NSError *error = nil;
				id decodedChild = nil;

				if (partialChildren) {
					decodedChild = [SPTJSONDecoding partialSPObjectFromDecodedJSON:jsonChild error:&error];
				} else {
					decodedChild = [SPTJSONDecoding SPObjectFromDecodedJSON:jsonChild error:&error];
				}

				if (decodedChild != nil) {
					[children addObject:decodedChild];
				}
			}

			if (children.count > 0) {
				self.items = [NSArray arrayWithArray:children];
			}
		}

		if ([pageObject[SPTListPageJSONOffsetKey] respondsToSelector:@selector(integerValue)])
			self.range = NSMakeRange([pageObject[SPTListPageJSONOffsetKey] integerValue], self.items.count);

	}
	return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@-%@ of %@ items", [super description],
			@(self.range.location), @(self.range.location + self.range.length - 1), @(self.totalListLength)];
}

-(BOOL)hasNextPage {
	return self.nextPageURL != nil;
}

-(BOOL)hasPreviousPage {
	return self.previousPageURL != nil;
}

-(BOOL)isComplete {
	return ![self hasPreviousPage] && ![self hasNextPage];
}

-(SPTListPage *)pageByAppendingPage:(SPTListPage *)nextPage {

	NSAssert(self.range.location + self.range.length == nextPage.range.location, @"Parameter nextPage must directly follow receiver");

	SPTListPage *newPage = [SPTListPage new];

	newPage.previousPageURL = self.previousPageURL;
	newPage.nextPageURL = nextPage.nextPageURL;
	newPage.totalListLength = nextPage.totalListLength;
	newPage.range = NSMakeRange(self.range.location, self.range.length + nextPage.range.length);
	newPage.hasPartialChildren = self.hasPartialChildren;
	newPage.rootObjectKey = self.rootObjectKey;

	NSMutableArray *newItems = [NSMutableArray arrayWithCapacity:newPage.range.length];
	[newItems addObjectsFromArray:self.items];
	[newItems addObjectsFromArray:nextPage.items];
	if (newItems.count > 0)
		newPage.items = newItems;

	return newPage;
}

-(void)requestNextPageWithAccessToken:(NSString *)accessToken callback:(SPTRequestCallback)block {
	[self requestPageAtURL:self.nextPageURL accessToken:accessToken callback:block];
}

-(void)requestPreviousPageWithAccessToken:(NSString *)accessToken  callback:(SPTRequestCallback)block {
	[self requestPageAtURL:self.previousPageURL accessToken:accessToken callback:block];
}

- (NSURLRequest*)createRequestForNextPageWithAccessToken:(NSString *)accessToken error:(NSError**)error {
	return [SPTRequest createRequestForURL:self.nextPageURL
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:nil
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:NO
									 error:error];
}

- (NSURLRequest*)createRequestForPreviousPageWithAccessToken:(NSString *)accessToken error:(NSError**)error {
	return [SPTRequest createRequestForURL:self.previousPageURL
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:nil
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:NO
									 error:error];
}



+ (instancetype)listPageFromData:(NSData *)data
					withResponse:(NSURLResponse *)response
		expectingPartialChildren:(BOOL)hasPartialChildren
				   rootObjectKey:(NSString *)rootObjectKey
						   error:(NSError **)error {
	
	NSError *decodeerror = nil;
	id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeerror];
	
	if (decodeerror != nil) {
		*error = decodeerror;
		return nil;
	}
	
	return [self listPageFromDecodedJSON:decodedObj
				expectingPartialChildren:hasPartialChildren
						   rootObjectKey:rootObjectKey
								   error:error];
}

+ (instancetype)listPageFromDecodedJSON:(id)decodedObject
			   expectingPartialChildren:(BOOL)hasPartialChildren
						  rootObjectKey:(NSString *)rootObjectKey
								  error:(NSError **)error {
	
	return [[SPTListPage alloc] initWithDecodedJSONObject:decodedObject
								 expectingPartialChildren:hasPartialChildren
											rootObjectKey:rootObjectKey];
}

-(void)requestPageAtURL:(NSURL *)url accessToken:(NSString *)accessToken callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;
	NSURLRequest *req = [SPTRequest createRequestForURL:url withAccessToken:accessToken error:&reqerr];
	if (reqerr != nil) {
		if (block) block([NSError errorWithDomain:@"com.spotify.ios-sdk" code:103 userInfo:nil], nil);
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		
		NSError *parseerr = nil;
		
		SPTListPage *newPage = [SPTListPage listPageFromData:data
												withResponse:response
									expectingPartialChildren:self.hasPartialChildren
											   rootObjectKey:self.rootObjectKey
													   error:&parseerr];
		if (parseerr != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(parseerr, nil); });
			return;
		}

		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, newPage); });

	}];
}

+(instancetype)listPageFromData:(NSData *)data withResponse:(NSURLResponse *)response error:(NSError **)error {
	if (data == nil) {
		if (error != nil) {
			*error = [NSError errorWithDomain:@"com.spotify.ios-sdk" code:401 userInfo:nil];
		}
		return nil;
	}
	
	NSError *error2 = nil;
	id decodedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error2];
	if (error2 != nil) {
		*error = error2;
		return nil;
	}
	
	return [[SPTListPage alloc] initWithDecodedJSONObject:decodedObj
								 expectingPartialChildren:true
											rootObjectKey:@"albums"];
}

-(NSArray *)tracksForPlayback {
	return self.items;
}

-(NSURL *)playableUri {
	return nil; // this isn't supported by esdk.
}

@end
