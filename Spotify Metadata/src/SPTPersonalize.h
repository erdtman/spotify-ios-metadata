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

#import <Foundation/Foundation.h>
#import "SPTRequest.h"
#import "SPTListPage.h"

/** This class provides helpers for using the personalization features in the Spotify API, See: https://developer.spotify.com/web-api/web-api-personalization-endpoints/ */
@interface SPTPersonalize : NSObject

/// Defines the types of top preferences
typedef NS_ENUM(NSUInteger, SPTPersonalizeType) {
	/// Specifies to get details of top artists.
	SPTPersonalizeTypeArtists,
	/// Specifies to get details of top tracks.
	SPTPersonalizeTypeTracks,
};

/// Defines the different time ranges to use to compute top artists or tracks
typedef NS_ENUM(NSUInteger, SPTPersonalizeTimeRange) {
	/// Specifies the last 4 weeks.
	SPTPersonalizeTimeRangeShort,
	/// Specifies the last 6 months.
	SPTPersonalizeTimeRangeMedium,
	/// Specifies the last several years.
	SPTPersonalizeTimeRangeLong,
};


///----------------------------
/// @name Convenience Methods
///----------------------------
/** Gets the current user's top artists or tracks

 This is a convenience method around the createRequest equivalent and the current `SPTRequestHandlerProtocol`

 @param type The type (artists or tracks) to compute.
 @param offset The index at which to start returning results.
 @param accessToken  An authenticated access token. Must be valid and authorized with the `user-top-read` scope.
 @param timeRange The time frame over which affinities are computed.
 @param block The block to be called when the operation is complete. The block will pass an `SPTListPage` containing results on success, otherwise an error.
 */
+(void)requestUsersTopWithType:(SPTPersonalizeType)type
						offset:(NSInteger)offset
				   accessToken:(NSString *)accessToken
					 timeRange:(SPTPersonalizeTimeRange)timeRange
					  callback:(SPTRequestCallback)block;


/** Gets the current user's top artists or tracks

 This is a convenience method around the createRequest equivalent and the current `SPTRequestHandlerProtocol`

 @param type The type (artists or tracks) to compute.
 @param accessToken  An authenticated access token. Must be valid and authorized with the `user-top-read` scope.
 @param block The block to be called when the operation is complete. The block will pass an `SPTListPage` containing results on success, otherwise an error.
 */
+(void)requestUsersTopWithType:(SPTPersonalizeType)type
				   accessToken:(NSString *)accessToken
					  callback:(SPTRequestCallback)block;


///----------------------------
/// @name API Request Factories
///----------------------------

/** Create a request for getting the current user's top artists or tracks

 @param type The type (artists or tracks) to compute.
 @param offset The index at which to start returning results.
 @param accessToken  An authenticated access token. Must be valid and authorized with the `user-top-read` scope.
 @param timeRange The time frame over which affinities are computed.
 @param error An optional pointer to an `NSError` that will receive the error code if operation failed.
 */
+(NSURLRequest*)createRequestForUsersTopWithType:(SPTPersonalizeType)type
										  offset:(NSInteger)offset
									 accessToken:(NSString *)accessToken
									   timeRange:(SPTPersonalizeTimeRange)timeRange
										   error:(NSError**)error;

/** Create a request for getting the current user's top artists or tracks

 @param type The type (artists or tracks) to compute.
 @param accessToken  An authenticated access token. Must be valid and authorized with the `user-top-read` scope.
 @param error An optional pointer to an `NSError` that will receive the error code if operation failed.
 */
+(NSURLRequest*)createRequestForUsersTopWithType:(SPTPersonalizeType)type
									 accessToken:(NSString *)accessToken
										   error:(NSError**)error;

@end
