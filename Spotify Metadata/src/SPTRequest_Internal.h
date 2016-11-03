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

#import "SPTRequest.h"

#define SP_DISPATCH_ASYNC_BLOCK_AND_EXIT_IF_ERROR(err) \
	if (err != nil) { \
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(err, nil); }); \
		return; \
	}

#define SP_DISPATCH_ASYNC_BLOCK_RESULT(result) \
	if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, result); });

@interface SPTRequest (SPTRequestInternal)

FOUNDATION_EXPORT NSString * const SPTErrorDomain;

+ (void) queueMockResponse:(NSString *)response;
+ (void) queueMockResponse:(NSString *)response withStatusCode:(int)statusCode;

+(NSData *)performRequestAtURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken accessTokenType:(NSString *)accessTokenType httpMethod:(NSString *)httpMethod values:(id)values error:(NSError **)error;
+ (NSData *)performRequestAtURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken accessTokenType:(NSString *)accessTokenType httpMethod:(NSString *)httpMethod values:(id)values valueBodyIsJSON:(BOOL)encodeAsJSON sendDataAsQueryString:(BOOL)dataAsQueryString error:(NSError **)error;

+ (NSURLRequest *)createRequestForURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken error:(NSError **)error;
+ (NSURLRequest *)createRequestForURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken httpMethod:(NSString *)httpMethod values:(id)values error:(NSError **)error;
+ (NSURLRequest *)createRequestForURL:(NSURL *)lookupUrl withAccessToken:(NSString *)accessToken httpMethod:(NSString *)httpMethod values:(id)values valueBodyIsJSON:(BOOL)encodeAsJSON error:(NSError **)error;

+(void)performSequentialMultiget:(NSArray *)inputs
						   pager:(void (^)(NSArray *inputs, SPTRequestCallback callback))pager
					    pagesize:(int)pagesize
						callback:(SPTRequestCallback)callback;

+(NSString *)urlEncodeString:(NSString *)str;

+(NSError *)createError:(int)errorCode withDescription:(NSString*)description;

+(void)setErrorCode:(int)errorcode withDescription:(NSString *)description toError:(NSError **)error;

@end

@interface SPTDefaultRequestHandler : NSObject<SPTRequestHandlerProtocol>

@end