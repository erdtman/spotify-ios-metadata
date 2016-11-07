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

#import "SPTSearch.h"
#import "SPTRequest_Internal.h"
#import "SPTListPage_Internal.h"

@implementation SPTSearch

+(NSString *)typeNameFromSearchQueryType:(SPTSearchQueryType)searchQueryType {
	if (searchQueryType == SPTQueryTypeTrack) {
		return @"track";
	}
	if (searchQueryType == SPTQueryTypeArtist) {
		return @"artist";
	}
	if (searchQueryType == SPTQueryTypeAlbum) {
		return @"album";
	}
	if (searchQueryType == SPTQueryTypePlaylist) {
		return @"playlist";
	}
	return @"";
};

+(NSString *)rootObjectNameFromSearchQueryType:(SPTSearchQueryType)searchQueryType {
	if (searchQueryType == SPTQueryTypeTrack) {
		return @"tracks";
	}
	if (searchQueryType == SPTQueryTypeArtist) {
		return @"artists";
	}
	if (searchQueryType == SPTQueryTypeAlbum) {
		return @"albums";
	}
	if (searchQueryType == SPTQueryTypePlaylist) {
		return @"playlists";
	}
	return @"";
};

+(SPTListPage *)searchResultsFromDecodedJSON:(id)decodedObject
								   queryType:(SPTSearchQueryType)searchQueryType
									   error:(NSError **)error {
	return [[SPTListPage alloc] initWithDecodedJSONObject:decodedObject
								 expectingPartialChildren:YES
											rootObjectKey:[self rootObjectNameFromSearchQueryType:searchQueryType]];
}

+(SPTListPage *)searchResultsFromData:(NSData *)data
						 withResponse:(NSURLResponse *)response
							queryType:(SPTSearchQueryType)searchQueryType
								error:(NSError **)error {

	NSError *err = nil;
	if (data == nil) {
		*error = [NSError errorWithDomain:@"com.spotify.ios-sdk" code:104 userInfo:nil];
		return nil;
	}
	id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
	if (err != nil) {
		*error = err;
		return nil;
	}
	
	return [self searchResultsFromDecodedJSON:json queryType:searchQueryType error:error];
}

+(void)performSearchWithQuery:(NSString *)searchQuery
					queryType:(SPTSearchQueryType)searchQueryType
					   offset:(NSInteger)offset
				  accessToken:(NSString *)accessToken
					   market:(NSString *)market
					 callback:(SPTRequestCallback)block {
	
	NSError *reqerr = nil;

	NSURLRequest *req = [self createRequestForSearchWithQuery:searchQuery
													queryType:searchQueryType
													   offset:offset
												  accessToken:accessToken
													   market:market
														error:&reqerr];
	
	if (reqerr != nil) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(reqerr, nil); });
		return;
	}
	
	[[SPTRequest sharedHandler] performRequest:req callback:^(NSError *error, NSURLResponse *response, NSData *data) {
		
		NSError *resperr = nil;
		SPTListPage *page = [self searchResultsFromData:data withResponse:response queryType:searchQueryType error:&resperr];
		if (resperr != nil) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(resperr, nil); });
			return;
		}
		
		if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(nil, page); });
	}];
}

+(NSURLRequest*)createRequestForSearchWithQuery:(NSString *)searchQuery
									  queryType:(SPTSearchQueryType)searchQueryType
										 offset:(NSInteger)offset
									accessToken:(NSString *)accessToken
										 market:(NSString *)market
										  error:(NSError**)error {
	
	NSURL *searchUrl = [NSURL URLWithString:@"https://api.spotify.com/v1/search"];
	NSDictionary *values = [NSMutableDictionary dictionary];
	
	[values setValue:[self typeNameFromSearchQueryType:searchQueryType] forKey:@"type"];
	[values setValue:searchQuery forKey:@"q"];
	if (market != nil) {
		[values setValue:market forKey:@"market"];
	}
	[values setValue:@(20) forKey:@"limit"];
	[values setValue:@(offset) forKey:@"offset"];
	
	return [SPTRequest createRequestForURL:searchUrl
						   withAccessToken:accessToken
								httpMethod:@"GET"
									values:values
						   valueBodyIsJSON:NO
					 sendDataAsQueryString:YES
									 error:error];
}

+(void)performSearchWithQuery:(NSString *)searchQuery
					queryType:(SPTSearchQueryType)searchQueryType
				  accessToken:(NSString *)accessToken
					   market:(NSString *)market
					 callback:(SPTRequestCallback)block {
	[self performSearchWithQuery:searchQuery queryType:searchQueryType offset:0 accessToken:accessToken market:market callback:block];
}

+(NSURLRequest*)createRequestForSearchWithQuery:(NSString *)searchQuery
									  queryType:(SPTSearchQueryType)searchQueryType
									accessToken:(NSString *)accessToken
										 market:(NSString *)market
										  error:(NSError**)error {
	return [self createRequestForSearchWithQuery:searchQuery queryType:searchQueryType offset:0 accessToken:accessToken market:market error:error];
}

+(void)performSearchWithQuery:(NSString *)searchQuery
					queryType:(SPTSearchQueryType)searchQueryType
					   offset:(NSInteger)offset
				  accessToken:(NSString *)accessToken
					 callback:(SPTRequestCallback)block {
	[self performSearchWithQuery:searchQuery queryType:searchQueryType offset:offset accessToken:accessToken market:nil callback:block];
}

+(NSURLRequest*)createRequestForSearchWithQuery:(NSString *)searchQuery
									  queryType:(SPTSearchQueryType)searchQueryType
										 offset:(NSInteger)offset
									accessToken:(NSString *)accessToken
										  error:(NSError**)error {
	return [self createRequestForSearchWithQuery:searchQuery queryType:searchQueryType offset:offset accessToken:accessToken market:nil error:error];
}

+(void)performSearchWithQuery:(NSString *)searchQuery
					queryType:(SPTSearchQueryType)searchQueryType
				  accessToken:(NSString *)accessToken
					 callback:(SPTRequestCallback)block {
	[self performSearchWithQuery:searchQuery queryType:searchQueryType offset:0 accessToken:accessToken market:nil callback:block];
}

+(NSURLRequest*)createRequestForSearchWithQuery:(NSString *)searchQuery
									  queryType:(SPTSearchQueryType)searchQueryType
									accessToken:(NSString *)accessToken
										  error:(NSError**)error {
	return [self createRequestForSearchWithQuery:searchQuery queryType:searchQueryType offset:0 accessToken:accessToken market:nil error:error];
}

@end
