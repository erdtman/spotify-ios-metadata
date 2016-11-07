##########################################
# Copyright (c) 2016 Spotify AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################

##########################################
#
# c.f. http://stackoverflow.com/questions/3520977/build-fat-static-library-device-simulator-using-xcode-and-sdk-4
#
set -e -u -x
set -o pipefail

#################[ Tests: helps workaround any future bugs in Xcode ]########
#
DEBUG_THIS_SCRIPT="false"

if [ $DEBUG_THIS_SCRIPT = "true" ]
then
echo "########### TESTS #############"
echo "Use the following variables when debugging this script; note that they may change on recursions"
echo "BUILD_DIR = $BUILD_DIR"
echo "BUILD_ROOT = $BUILD_ROOT"
echo "CONFIGURATION_BUILD_DIR = $CONFIGURATION_BUILD_DIR"
echo "BUILT_PRODUCTS_DIR = $BUILT_PRODUCTS_DIR"
echo "CONFIGURATION_TEMP_DIR = $CONFIGURATION_TEMP_DIR"
echo "TARGET_BUILD_DIR = $TARGET_BUILD_DIR"
fi

#####################[ part 1 ]##################
# First, work out the BASESDK version number (NB: Apple ought to report this, but they hide it)
#    (incidental: searching for substrings in sh is a nightmare! Sob)

SDK_VERSION=$(echo ${SDK_NAME} | grep -oE '[0-9.]+$')

# Next, work out if we're in SIM or DEVICE

if [ ${PLATFORM_NAME} = "iphonesimulator" ]
then
OTHER_SDK_TO_BUILD=iphoneos${SDK_VERSION}
else
OTHER_SDK_TO_BUILD=iphonesimulator${SDK_VERSION}
fi

echo "XCode has selected SDK: ${PLATFORM_NAME} with version: ${SDK_VERSION} (although back-targetting: ${IPHONEOS_DEPLOYMENT_TARGET})"
echo "...therefore, OTHER_SDK_TO_BUILD = ${OTHER_SDK_TO_BUILD}"
#
#####################[ end of part 1 ]##################

#####################[ part 2 ]##################
#
# IF this is the original invocation, invoke WHATEVER other builds are required
#
# Xcode is already building ONE target...
#
# ...but this is a LIBRARY, so Apple is wrong to set it to build just one.
# ...we need to build ALL targets
# ...we MUST NOT re-build the target that is ALREADY being built: Xcode WILL CRASH YOUR COMPUTER if you try this (infinite recursion!)
#
#
# So: build ONLY the missing platforms/configurations.

if [ "true" == ${ALREADYINVOKED:-false} ]
then
echo "RECURSION: I am NOT the root invocation, so I'm NOT going to recurse"
else
# CRITICAL:
# Prevent infinite recursion (Xcode sucks)
export ALREADYINVOKED="true"

echo "RECURSION: I am the root ... recursing all missing build targets NOW..."
echo "RECURSION: ...about to invoke: xcodebuild -configuration \"${CONFIGURATION}\" -project \"${PROJECT_NAME}.xcodeproj\" -target \"${TARGET_NAME}\" -sdk \"${OTHER_SDK_TO_BUILD}\" ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO" BUILD_DIR=\"${BUILD_DIR}\" BUILD_ROOT=\"${BUILD_ROOT}\" SYMROOT=\"${SYMROOT}\"

xcodebuild -configuration "${CONFIGURATION}" -project "${PROJECT_NAME}.xcodeproj" -target "${TARGET_NAME}" -sdk "${OTHER_SDK_TO_BUILD}" ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" WARNING_CFLAGS=""

ACTION="build"

#Merge all platform binaries as a fat binary for each configurations.

# Calculate where the (multiple) built files are coming from:
CURRENTCONFIG_DEVICE_DIR=${SYMROOT}/${CONFIGURATION}-iphoneos
CURRENTCONFIG_SIMULATOR_DIR=${SYMROOT}/${CONFIGURATION}-iphonesimulator

echo "Taking device build from: ${CURRENTCONFIG_DEVICE_DIR}"
echo "Taking simulator build from: ${CURRENTCONFIG_SIMULATOR_DIR}"

UNIVERSAL_PRODUCTS_DIR=${SYMROOT}/${CONFIGURATION}-universal
echo "...I will output a universal build to: ${UNIVERSAL_PRODUCTS_DIR}"

# ... remove the products of previous runs of this script
#      NB: this directory is ONLY created by this script - it should be safe to delete!

echo "Copying built product in ${UNIVERSAL_PRODUCTS_DIR}"
rm -rf "${UNIVERSAL_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}"
mkdir -p "${UNIVERSAL_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}"

echo "Creating universal framework ${FULL_PRODUCT_NAME}"
cp -rf "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}" "${UNIVERSAL_PRODUCTS_DIR}"
echo "lipo: for current configuration (${CONFIGURATION}) creating output file: ${UNIVERSAL_PRODUCTS_DIR}/${EXECUTABLE_PATH}"
xcrun -sdk iphoneos lipo -create -output "${UNIVERSAL_PRODUCTS_DIR}/${EXECUTABLE_PATH}" "${CURRENTCONFIG_DEVICE_DIR}/${EXECUTABLE_PATH}" "${CURRENTCONFIG_SIMULATOR_DIR}/${EXECUTABLE_PATH}"
fi
