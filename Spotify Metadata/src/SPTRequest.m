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

#import "SPTRequest.h"
#import "SPTRequest_Internal.h"
#import "SPTJSONDecoding.h"
#import "SPTPlaylistList.h"
#import "SPTListPage_Internal.h"
#import "SPTFeaturedPlaylistList.h"
#import "SPTFeaturedPlaylistList_Internal.h"

static NSString * const SPTAuthorizationHeaderKey = @"Authorization";
NSString * const SPTMarketFromToken = @"from_token";
NSString * const SPTErrorDomain = @"com.spotify.ios-sdk";


@implementation SPTRequest

static id<SPTRequestHandlerProtocol> currentRequestHandler;
static NSMutableDictionary *extrasStorage;
static NSMutableArray *mockResponses = nil;

+ (void) clearMockResponses {
	if (mockResponses == nil)
		mockResponses = [NSMutableArray array];
	[mockResponses removeAllObjects];
}

+(void) queueMockResponse:(NSString *)response {
	[self queueMockResponse:response withStatusCode:200];
}

+(void) queueMockResponse:(NSString *)response withStatusCode:(int)statusCode {
	if (mockResponses == nil)
		mockResponses = [NSMutableArray array];

	NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
	NSArray *resp = [NSArray arrayWithObjects:data, [NSNumber numberWithInt:statusCode], nil];
	[mockResponses addObject:resp];
}

+(NSData *)performRequestAtURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken accessTokenType:(NSString *)accessTokenType httpMethod:(NSString *)httpMethod values:(id)values error:(NSError **)error {
	return [self performRequestAtURL:lookupUrl withAccessToken:accessToken accessTokenType:accessTokenType httpMethod:httpMethod values:values valueBodyIsJSON:NO error:error];
}

+(NSData *)performRequestAtURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken accessTokenType:(NSString *)accessTokenType httpMethod:(NSString *)httpMethod values:(id)values valueBodyIsJSON:(BOOL)encodeAsJSON error:(NSError **)error {
	return [self performRequestAtURL:lookupUrl withAccessToken:accessToken accessTokenType:accessTokenType httpMethod:httpMethod values:values valueBodyIsJSON:encodeAsJSON sendDataAsQueryString:NO error:error];
}

+(NSData *)performRequestAtURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken accessTokenType:(NSString *)accessTokenType httpMethod:(NSString *)httpMethod values:(id)values valueBodyIsJSON:(BOOL)encodeAsJSON sendDataAsQueryString:(BOOL)dataAsQueryString error:(NSError **)error {
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:lookupUrl];
	
	NSURLResponse *response = nil;
	NSData *returnData = nil;
	NSUInteger statusCode = 200;

	if (mockResponses != nil && mockResponses.count > 0) {

		NSArray *mockinfo = [mockResponses objectAtIndex:0];
		NSData *mockData = mockinfo[0];
		NSNumber *mockStatus = mockinfo[1];
		[mockResponses removeObjectAtIndex:0];
		statusCode = [mockStatus integerValue];
		returnData = mockData;

	} else {

		request.HTTPMethod = httpMethod.length == 0 ? @"GET" : httpMethod;
		
		if (values != nil) {
			NSMutableArray *encodedPairs = [NSMutableArray array];
			
			if ([values isKindOfClass:[NSDictionary class]]) {
				
				for (NSString *key in values) {
					
					id value = values[key];
					
					if ([value isKindOfClass:[NSArray class]]) {
						for (id subValue in value) {
							NSString *stringValue = [NSString stringWithFormat:@"%@", subValue];
							[encodedPairs addObject:[NSString stringWithFormat:@"%@=%@", [self urlEncodeString:key], [self urlEncodeString:stringValue]]];
						}
					} else {
						NSString *stringValue = [NSString stringWithFormat:@"%@", value];
						[encodedPairs addObject:[NSString stringWithFormat:@"%@=%@", [self urlEncodeString:key], [self urlEncodeString:stringValue]]];
					}
				}
			}
			
			NSString *requestString = [encodedPairs componentsJoinedByString:@"&"];
			
			if ([httpMethod caseInsensitiveCompare:@"GET"] == NSOrderedSame || httpMethod.length == 0 || dataAsQueryString) {
				NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", lookupUrl.absoluteString, requestString]];
				request.URL = newURL;
			} else {
				if (encodeAsJSON) {
					[request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
					if (values != nil && [NSJSONSerialization isValidJSONObject:values]) {
						NSData *body = [NSJSONSerialization dataWithJSONObject:values options:NSJSONWritingPrettyPrinted error:nil];
						[request setHTTPBody:body];
					}
				} else {
					[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
					[request setHTTPBody:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
				}
			}
		}
		
		if (accessToken && accessTokenType) {
			NSString *authorizationHeaderValue =[NSString stringWithFormat:@"%@ %@", accessTokenType, accessToken];
			[request setValue:authorizationHeaderValue forHTTPHeaderField:SPTAuthorizationHeaderKey];
		}

		[request setTimeoutInterval:10.0];
		returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
	}
	
	if (returnData == nil)
		return nil;

	if (response != nil && [response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		statusCode = httpResponse.statusCode;
	}

	if (statusCode < 200 || statusCode > 299) {
		if (error != NULL) *error = [NSError errorWithDomain:@"com.spotify.ios-sdk"
														code:statusCode
													userInfo:@{ NSLocalizedDescriptionKey : [NSHTTPURLResponse localizedStringForStatusCode:statusCode]}];
	}

	return returnData;

}


+(NSString *)urlEncodeString:(NSString *)str {
	return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																				 (CFStringRef)str,
																				 NULL,
																				 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
																				 kCFStringEncodingUTF8);
}


+(void)performSequentialMultiget:(NSArray *)inputs
						   pager:(void (^)(NSArray *inputs, SPTRequestCallback callback))pager
					    pagesize:(int)pagesize
						callback:(SPTRequestCallback)callback {
	
	if (inputs == nil) {
		if (callback) callback([NSError errorWithDomain:@"com.spotify.ios-sdk" code:103 userInfo:nil], nil);
		return;
	}

	[self recursivelyRequestItems:inputs
						withPager:pager
						 pageSize:pagesize
		   previouslyFetchedItems:nil
						 callback:callback];
}

+(void)recursivelyRequestItems:(NSArray *)remainingItems
					 withPager:(void (^)(NSArray *inputs, SPTRequestCallback callback))pager
					  pageSize:(NSUInteger)pageSize
		previouslyFetchedItems:(NSArray *)fetchedItems
					  callback:(SPTRequestCallback)callback {

	if (remainingItems.count == 0) {
		// we're done, call final callback with result.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			callback(nil, fetchedItems);
		});
		return;
	}

	// we have stuff to request, query for maximum `limit` number of items.
	NSUInteger numberOfItemsToRequest = remainingItems.count < pageSize ? remainingItems.count : pageSize;
	NSArray *thisCall = [remainingItems subarrayWithRange:NSMakeRange(0, numberOfItemsToRequest)];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

		pager(thisCall, ^void(NSError *error, id obj) {
			if (error != nil) {
				callback(error, nil);
				return;
			}

			NSMutableArray *newFetchedItems = [fetchedItems mutableCopy];
			if (newFetchedItems == nil) {
				newFetchedItems = [NSMutableArray new];
			}

			NSArray *pageResultArray = (NSArray *)obj;
			[newFetchedItems addObjectsFromArray:pageResultArray];

			NSMutableArray *remainingItemsAfterThisCall = [remainingItems mutableCopy];
			[remainingItemsAfterThisCall removeObjectsInRange:NSMakeRange(0, numberOfItemsToRequest)];

			// and request next page, or finish.
			[self recursivelyRequestItems:remainingItemsAfterThisCall
								withPager:pager
								 pageSize:pageSize
				   previouslyFetchedItems:newFetchedItems
								 callback:callback];
		});
	});
}

+(id<SPTRequestHandlerProtocol>)sharedHandler {
	if (currentRequestHandler == nil) {
		currentRequestHandler = [SPTDefaultRequestHandler new];
	}

	return currentRequestHandler;
}

+(void)setSharedHandler:(id<SPTRequestHandlerProtocol>)handler {
	currentRequestHandler = handler;
}

+(NSURLRequest *)createRequestForURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken error:(NSError **)error {
	return [self createRequestForURL:lookupUrl withAccessToken:accessToken httpMethod:@"GET" values:nil valueBodyIsJSON:NO error:error];
}

+(NSURLRequest *)createRequestForURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken httpMethod:(NSString *)httpMethod values:(id)values error:(NSError **)error {
	return [self createRequestForURL:lookupUrl withAccessToken:accessToken httpMethod:httpMethod values:values valueBodyIsJSON:NO error:error];
}

+(NSURLRequest *)createRequestForURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken httpMethod:(NSString *)httpMethod values:(id)values valueBodyIsJSON:(BOOL)encodeAsJSON error:(NSError **)error {
	return [self createRequestForURL:lookupUrl withAccessToken:accessToken httpMethod:httpMethod values:values valueBodyIsJSON:encodeAsJSON sendDataAsQueryString:NO error:error];
}

+(NSURLRequest *)createRequestForURL:(NSURL *)lookupUrl withAccessToken:accessToken httpMethod:(NSString *)httpMethod values:(id)values valueBodyIsJSON:(BOOL)encodeAsJSON sendDataAsQueryString:(BOOL)dataAsQueryString error:(NSError **)error {
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:lookupUrl];
	
	request.HTTPMethod = httpMethod.length == 0 ? @"GET" : httpMethod;
	
	if (values != nil) {
		NSMutableArray *encodedPairs = [NSMutableArray array];
		
		if ([values isKindOfClass:[NSDictionary class]]) {
			
			for (NSString *key in values) {
				
				id value = values[key];
				
				if ([value isKindOfClass:[NSArray class]]) {
					for (id subValue in value) {
						NSString *stringValue = [NSString stringWithFormat:@"%@", subValue];
						[encodedPairs addObject:[NSString stringWithFormat:@"%@=%@", [self urlEncodeString:key], [self urlEncodeString:stringValue]]];
					}
				} else {
					NSString *stringValue = [NSString stringWithFormat:@"%@", value];
					[encodedPairs addObject:[NSString stringWithFormat:@"%@=%@", [self urlEncodeString:key], [self urlEncodeString:stringValue]]];
				}
			}
		}
		
		NSArray *sortedEncodedPairs = [encodedPairs sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
			NSString *first = a;
			NSString *second = b;
			return [first compare:second];
		}];
		
		NSString *requestString = [sortedEncodedPairs componentsJoinedByString:@"&"];
		if ([httpMethod caseInsensitiveCompare:@"GET"] == NSOrderedSame || httpMethod.length == 0 || dataAsQueryString) {
			NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", lookupUrl.absoluteString, requestString]];
			request.URL = newURL;
		} else {
			if (encodeAsJSON) {
				[request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
				if (values != nil && [NSJSONSerialization isValidJSONObject:values]) {
					NSData *body = [NSJSONSerialization dataWithJSONObject:values options:NSJSONWritingPrettyPrinted error:nil];
					[request setHTTPBody:body];
				}
			} else {
				[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
				[request setHTTPBody:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
			}
		}
	}
	
	if (accessToken != nil) {
		NSString *authorizationHeaderValue =[NSString stringWithFormat:@"Bearer %@", accessToken];
		[request setValue:authorizationHeaderValue forHTTPHeaderField:SPTAuthorizationHeaderKey];
	}
	
	[request setTimeoutInterval:10.0];
	return request;
}

+ (NSError *)createError:(int)errorCode withDescription:(NSString*)description {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:description forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:SPTErrorDomain code:errorCode userInfo:userInfo];
}

+ (void)setErrorCode:(int)errorcode withDescription:(NSString *)description toError:(NSError **)error {
	if (error != nil) {
		*error = [SPTRequest createError:errorcode withDescription:description];
	}
}

@end

@implementation  SPTDefaultRequestHandler

- (void)performRequest:(NSURLRequest *)request callback:(SPTRequestDataCallback)block {
	__block NSURLRequest *reqcopy = [request copy];
	// dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	[NSURLConnection sendAsynchronousRequest:reqcopy queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		if (connectionError != nil) {
			// connection error...
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(connectionError, nil, nil); });
			return;
		}

		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, response, data); });
	}];
	// });
}

@end

