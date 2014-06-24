/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */


#import "CDVCapture.h"
#import "JSONKit.h"
#import "CDVAvailability.h"
#import "CDVViewController.h"
#import "UIImage+fixOrientation.h"

#import "Geometry.h"
#import "UIImage-Utilities.h"
#import "Orientation.h"

#define kW3CMediaFormatHeight @"height"
#define kW3CMediaFormatWidth @"width"
#define kW3CMediaFormatCodecs @"codecs"
#define kW3CMediaFormatBitrate @"bitrate"
#define kW3CMediaFormatDuration @"duration"
#define kW3CMediaModeType @"type"

@implementation CDVImagePicker

@synthesize quality;
@synthesize callbackId;
@synthesize mimeType;

- (uint64_t)accessibilityTraits
{
    NSString* systemVersion = [[UIDevice currentDevice] systemVersion];

    if (([systemVersion compare:@"4.0" options:NSNumericSearch] != NSOrderedAscending)) { // this means system version is not less than 4.0
        return UIAccessibilityTraitStartsMediaSession;
    }

    return UIAccessibilityTraitNone;
}

@end

@implementation CDVCapture
@synthesize inUse;
@synthesize s3;
@synthesize tm;
@synthesize backgroundTaskId;

- (id)initWithWebView:(UIWebView*)theWebView
{
    self = (CDVCapture*)[super initWithWebView:theWebView];
    if (self) {
        self.inUse = NO;
    }
    return self;
}

- (void)captureAudio:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSDictionary* options = [command.arguments objectAtIndex:0];

    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }

    NSNumber* duration = [options objectForKey:@"duration"];
    // the default value of duration is 0 so use nil (no duration) if default value
    if (duration) {
        duration = [duration doubleValue] == 0 ? nil : duration;
    }
    CDVPluginResult* result = nil;

    if (NSClassFromString(@"AVAudioRecorder") == nil) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_NOT_SUPPORTED];
    } else if (self.inUse == YES) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_APPLICATION_BUSY];
    } else {
        // all the work occurs here
        CDVAudioRecorderViewController* audioViewController = [[CDVAudioRecorderViewController alloc] initWithCommand:self duration:duration callbackId:callbackId];

        // Now create a nav controller and display the view...
        CDVAudioNavigationController* navController = [[CDVAudioNavigationController alloc] initWithRootViewController:audioViewController];

        self.inUse = YES;

        if ([self.viewController respondsToSelector:@selector(presentViewController:::)]) {
            [self.viewController presentViewController:navController animated:YES completion:nil];
        } else {
            [self.viewController presentModalViewController:navController animated:YES];
        }
    }

    if (result) {
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}

- (void)captureImage:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSDictionary* options = [command.arguments objectAtIndex:0];

    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    NSString* mode = [options objectForKey:@"mode"];

    // options could contain limit and mode neither of which are supported at this time
    // taking more than one picture (limit) is only supported if provide own controls via cameraOverlayView property
    // can support mode in OS

    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSLog(@"Capture.imageCapture: camera not available.");
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_NOT_SUPPORTED];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    } else {
        if (pickerController == nil) {
            pickerController = [[CDVImagePicker alloc] init];
        }

        pickerController.delegate = self;
        pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        pickerController.allowsEditing = NO;
        if ([pickerController respondsToSelector:@selector(mediaTypes)]) {
            // iOS 3.0
            pickerController.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeImage, nil];
        }

        /*if ([pickerController respondsToSelector:@selector(cameraCaptureMode)]){
            // iOS 4.0
            pickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
            pickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            pickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        }*/
        // CDVImagePicker specific property
        pickerController.callbackId = callbackId;
        pickerController.mimeType = mode;

        if ([self.viewController respondsToSelector:@selector(presentViewController:::)]) {
            [self.viewController presentViewController:pickerController animated:YES completion:nil];
        } else {
            [self.viewController presentModalViewController:pickerController animated:YES];
        }
    }
}

- (void)processBackgroundThreadUpload:(NSString *)filePath forFilePathMedium:(NSString*)filePathMedium forFilePathThumb:(NSString*)filePathThumb forFileKey:(NSString*)key forFileKeyMedium:(NSString*)keyMedium forFileKeyThumb:(NSString*)keyThumb forMid:(NSString*)mid forMediaType:(NSString*)mediaType forCallbackId:(NSString*)callbackId
{
    NSLog(@"hello");
    if(self.s3 == nil) {
        // Initial the S3 Client.
        self.s3 = [[AmazonS3Client alloc] initWithAccessKey:@"---AWS KEY REMOVED---" withSecretKey:@"---AWS SECRET KEY REMOVED---"];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:filePath forKey:@"filePath"];
    [params setValue:filePathMedium forKey:@"filePathMedium"];
    [params setValue:filePathThumb forKey:@"filePathThumb"];
    [params setValue:key forKey:@"key"];
    [params setValue:keyMedium forKey:@"keyMedium"];
    [params setValue:keyThumb forKey:@"keyThumb"];
    [params setValue:mid forKey:@"mid"];
    [params setValue:mediaType forKey:@"mediaType"];
    [params setValue:callbackId forKey:@"callbackId"];
    
    if ([[UIDevice currentDevice] isMultitaskingSupported])
        backgroundTaskId = [NSNumber numberWithInt:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}]];
    
    [self performSelectorInBackground:@selector(processBackgroundThreadUploadInBackground:)
                           withObject:params];
    
}



-(void)request:(AmazonServiceRequest *)request didSendData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    //NSLog(@"didSendData called for %@: %d - %d / %d", request.requestTag, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    
    NSString *type = nil;
    NSString *mid = nil;
    NSString *mediaType = nil;
    NSString *callbackId = nil;
    
    NSArray *chunks = [request.requestTag componentsSeparatedByString: @":"];
    
    mediaType = [chunks objectAtIndex:2];
    
    if ( [mediaType isEqual: @"photo"] ) {
        type = [chunks objectAtIndex:0];
        mid = [chunks objectAtIndex:1];
        callbackId = [chunks objectAtIndex:3];
    } else {
        type = @"main";
        mediaType = @"video";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\.com/(\\d+)\\.MOV" options:NSRegularExpressionCaseInsensitive error:NULL];
        NSString *str = request.url.absoluteString;
        NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
        mid = [str substringWithRange:[match rangeAtIndex:1]];
        callbackId = self.callbackId;
    }
    
    
    NSMutableDictionary *resultParams = [NSMutableDictionary dictionaryWithObject:mid forKey:@"mid"];
    [resultParams setValue:mediaType forKey:@"mediaType"];
    [resultParams setValue:type forKey:@"uploadType"];
    [resultParams setValue:@"progress" forKey:@"typeOfPluginResult"];
    [resultParams setValue:[NSString stringWithFormat:@"%i", totalBytesWritten] forKey:@"totalBytesWritten"];
    [resultParams setValue:[NSString stringWithFormat:@"%i", totalBytesExpectedToWrite] forKey:@"totalBytesExpectedToWrite"];
    
    NSArray* resultArray = [NSArray arrayWithObject:resultParams];
    NSLog(@"resultArray %@", resultParams);
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultArray];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    //NSLog(@"didCompleteWithResponse called for %@: %@", request.requestTag, response);
    
    NSString *type = nil;
    NSString *mid = nil;
    NSString *mediaType = nil;
    NSString *callbackId = nil;
    
    NSArray *chunks = [request.requestTag componentsSeparatedByString: @":"];
    
    mediaType = [chunks objectAtIndex:2];
    
    if ( [mediaType isEqual: @"photo"] ) {
        type = [chunks objectAtIndex:0];
        mid = [chunks objectAtIndex:1];
        callbackId = [chunks objectAtIndex:3];
    } else {
        type = @"main";
        mediaType = @"video";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\.com/(\\d+)\\.MOV" options:NSRegularExpressionCaseInsensitive error:NULL];
        NSString *str = request.url.absoluteString;
        NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
        mid = [str substringWithRange:[match rangeAtIndex:1]];
        callbackId = self.callbackId;
    }
    
    NSMutableDictionary *resultParams = [NSMutableDictionary dictionaryWithObject:mid forKey:@"mid"];
    [resultParams setValue:mediaType forKey:@"mediaType"];
    [resultParams setValue:type forKey:@"uploadType"];
    [resultParams setValue:@"success" forKey:@"typeOfPluginResult"];
    if ([type isEqual: @"main"]) {
        [resultParams setValue:@"loaded" forKey:@"status"];
    }
    if ([type isEqual: @"medium"]) {
        [resultParams setValue:@"loaded" forKey:@"statusMedium"];
    }
    if ([type isEqual: @"thumb"]) {
        [resultParams setValue:@"loaded" forKey:@"statusThumb"];
    }
    
    NSArray* resultArray = [NSArray arrayWithObject:resultParams];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultArray];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    //NSLog(@"didFailWithError called for %@: %@", request.requestTag, error);
    
    NSString *type = nil;
    NSString *mid = nil;
    NSString *mediaType = nil;
    NSString *callbackId = nil;
    
    NSArray *chunks = [request.requestTag componentsSeparatedByString: @":"];
    
    mediaType = [chunks objectAtIndex:2];
    
    if ( [mediaType isEqual: @"photo"] ) {
        type = [chunks objectAtIndex:0];
        mid = [chunks objectAtIndex:1];
        callbackId = [chunks objectAtIndex:3];
    } else {
        type = @"main";
        mediaType = @"video";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\.com/(\\d+)\\.MOV" options:NSRegularExpressionCaseInsensitive error:NULL];
        NSString *str = request.url.absoluteString;
        NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
        mid = [str substringWithRange:[match rangeAtIndex:1]];
        callbackId = self.callbackId;
    }
    
    NSMutableDictionary *resultParams = [NSMutableDictionary dictionaryWithObject:mid forKey:@"mid"];
    [resultParams setValue:mediaType forKey:@"mediaType"];
    [resultParams setValue:type forKey:@"uploadType"];
    [resultParams setValue:@"failure" forKey:@"typeOfPluginResult"];
    
    NSArray* resultArray = [NSArray arrayWithObject:resultParams];
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultArray];
    [result setKeepCallbackAsBool:YES];
    
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    
}

- (void)processBackgroundThreadUpload:(NSDictionary *)params
{
    NSLog(@"start pbt");
    self.callbackId = (NSString *)[params valueForKey:@"callbackId"];
    
    if(self.s3 == nil) {
        // Initialize the S3 Client.
        self.s3 = [[AmazonS3Client alloc] initWithAccessKey:@"---AWS KEY REMOVED---" withSecretKey:@"---AWS SECRET KEY REMOVED---"];
    }
    
    if (self.tm == nil) {
        self.tm = [S3TransferManager new];
        self.tm.s3 = s3;
        self.tm.delegate = self;
    }
    
    if ( ! [[params valueForKey:@"keyMedium"] isEqual:[NSNull null]] ) {
        S3PutObjectRequest *porMedium = [[S3PutObjectRequest alloc] initWithKey:[params valueForKey:@"keyMedium"]
                                                                       inBucket:@"---AWS BUCKET NAME REMOVED---"];
        porMedium.filename    = [params valueForKey:@"filePathMedium"];
        porMedium.cannedACL   = [S3CannedACL publicRead];
        porMedium.requestTag = [NSString stringWithFormat:@"medium:%@:%@:%@", (NSString *)[params valueForKey:@"mid"], (NSString *)[params valueForKey:@"mediaType"], (NSString *)[params valueForKey:@"callbackId"]];
        NSLog(@"les do porMedium");
        [self.tm upload:porMedium];
    }
    
    if ( ! [[params valueForKey:@"keyThumb"] isEqual:[NSNull null]] ) {
        S3PutObjectRequest *porThumb = [[S3PutObjectRequest alloc] initWithKey:[params valueForKey:@"keyThumb"]
                                                                      inBucket:@"---AWS BUCKET NAME REMOVED---"];
        porThumb.filename    = [params valueForKey:@"filePathThumb"];
        porThumb.cannedACL   = [S3CannedACL publicRead];
        porThumb.requestTag = [NSString stringWithFormat:@"thumb:%@:%@:%@", (NSString *)[params valueForKey:@"mid"], (NSString *)[params valueForKey:@"mediaType"], (NSString *)[params valueForKey:@"callbackId"]];
        NSLog(@"les do porThumb");
        [self.tm upload:porThumb];
    }
    
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:[params valueForKey:@"key"]
                                                             inBucket:@"---AWS BUCKET NAME REMOVED---"];
    NSLog(@"before setDelegate");
    por.filename    = [params valueForKey:@"filePath"];
    por.cannedACL   = [S3CannedACL publicRead];
    por.requestTag = [NSString stringWithFormat:@"main:%@:%@:%@", (NSString *)[params valueForKey:@"mid"], (NSString *)[params valueForKey:@"mediaType"], (NSString *)[params valueForKey:@"callbackId"]];
    NSLog(@"les do por");
    NSLog(@"requestag for por: %@", por.requestTag);
    [self.tm upload:por];
}



 
/* Process a still image from the camera.
 * - create thumb, medium, and econ versions of original image, then initiate the upload of them
 *
 * IN:
 *  UIImage* image - the UIImage data returned from the camera
 *  NSString* callbackId
 */
- (void)processImage:(NSDictionary*)params
{
    UIImage* image = [[params objectForKey:@"image"] fixOrientation];
    NSString* callbackId = [params valueForKey:@"callbackId"];
    
    CDVPluginResult* result = nil;
    
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    unsigned int mid = ( arc4random() % 1000000000 ) + 1000000000; //1000000000 is max int i think, at least safely
    
    CGSize econSize = CGSizeMake(850.0f, 850.0f);
    UIImage *econ = [image fitInSize:econSize];
    NSData* data = UIImageJPEGRepresentation(econ, 0.4);
    
    CGSize mediumSize = CGSizeMake(320.0f, 320.0f);
    UIImage *medium = [image fillSize:mediumSize];
    NSData* mediumData = UIImageJPEGRepresentation(medium, 0.4);
    
    CGSize destSize = CGSizeMake(175.0f, 175.0f);
    UIImage *thumb = [image fillSize:destSize];
    NSData* thumbData = UIImageJPEGRepresentation(thumb, 0.3);
    
    // write to temp directory and return URI
    NSString* docsPath = [NSTemporaryDirectory ()stringByStandardizingPath];  // use file system temporary directory
    NSError* err = nil;
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    
    // generate unique file name
    NSString* filePath;
    do {
        filePath = [NSString stringWithFormat:@"%@/wsi_photo_%03d.jpg", docsPath, (rand() % 1000000000)];
    } while ([fileMgr fileExistsAtPath:filePath]);

    NSString* filePathMedium;
    do {
        filePathMedium = [NSString stringWithFormat:@"%@/wsi_photoMedium_%03d.jpg", docsPath, (rand() % 1000000000)];
    } while ([fileMgr fileExistsAtPath:filePathMedium]);
    
    NSString* filePathThumb;
    do {
        filePathThumb = [NSString stringWithFormat:@"%@/wsi_photoThumb_%03d.jpg", docsPath, (rand() % 1000000000)];
    } while ([fileMgr fileExistsAtPath:filePathThumb]);
    
    
    if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
        NSLog(@"Error saving image");
    } else {
        if (![mediumData writeToFile:filePathMedium options:NSAtomicWrite error:&err]) {
            NSLog(@"Error saving medium image");
        } else {
            if (![thumbData writeToFile:filePathThumb options:NSAtomicWrite error:&err]) {
                NSLog(@"Error saving thumb image");
            } else {
                NSDictionary* staticFileDict = [self getMediaDictionaryFromPath:filePath ofType:nil];
                NSDictionary* staticMediumDict = [self getMediaDictionaryFromPath:filePathMedium ofType:nil];
                NSDictionary* staticThumbDict = [self getMediaDictionaryFromPath:filePathThumb ofType:nil];
                NSMutableDictionary* fileDict = [staticFileDict mutableCopy];
                NSMutableDictionary* mediumDict = [staticMediumDict mutableCopy];
                NSMutableDictionary* thumbDict = [staticThumbDict mutableCopy];
                [fileDict setValue:[NSString stringWithFormat:@"%i", mid] forKey:@"mid"];
                [fileDict setValue:@"photo" forKey:@"mediaType"];
                [fileDict setValue:@"initialRecordInformer" forKey:@"typeOfPluginResult"];
                [fileDict setValue:[fileDict objectForKey:@"fullPath"] forKey:@"filePath"];
                [fileDict setValue:[mediumDict objectForKey:@"fullPath"] forKey:@"filePathMedium"];
                [fileDict setValue:[thumbDict objectForKey:@"fullPath"] forKey:@"filePathThumb"];
                
                NSArray* fileArray = [NSArray arrayWithObject:fileDict];
                
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
                [result setKeepCallbackAsBool:YES];
                
                [self.commandDelegate sendPluginResult:result callbackId:callbackId];
                
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:filePath forKey:@"filePath"];
                [params setValue:filePathMedium forKey:@"filePathMedium"];
                [params setValue:filePathThumb forKey:@"filePathThumb"];
                [params setValue:[NSString stringWithFormat:@"econ_%i.jpg", mid] forKey:@"key"];
                [params setValue:[NSString stringWithFormat:@"medium_%i.jpg", mid] forKey:@"keyMedium"];
                [params setValue:[NSString stringWithFormat:@"thumb_%i.jpg", mid] forKey:@"keyThumb"];
                [params setValue:[NSString stringWithFormat:@"%i", mid] forKey:@"mid"];
                [params setValue:@"photo" forKey:@"mediaType"];
                [params setValue:(NSString*)callbackId forKey:@"callbackId"];
                
                
                [self performSelectorOnMainThread:@selector(processBackgroundThreadUpload:)
                                       withObject:params
                                    waitUntilDone:NO];
            }
        }
    }
    
    return;
}

- (void)captureVideo:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSDictionary* options = [command.arguments objectAtIndex:0];

    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }

    // options could contain limit, duration and mode, only duration is supported (but is not due to apple bug)
    // taking more than one video (limit) is only supported if provide own controls via cameraOverlayView property
    // NSNumber* duration = [options objectForKey:@"duration"];
    NSString* mediaType = nil;

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // there is a camera, it is available, make sure it can do movies
        pickerController = [[CDVImagePicker alloc] init];

        NSArray* types = nil;
        if ([UIImagePickerController respondsToSelector:@selector(availableMediaTypesForSourceType:)]) {
            types = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
            // NSLog(@"MediaTypes: %@", [types description]);

            if ([types containsObject:(NSString*)kUTTypeMovie]) {
                mediaType = (NSString*)kUTTypeMovie;
            } else if ([types containsObject:(NSString*)kUTTypeVideo]) {
                mediaType = (NSString*)kUTTypeVideo;
            }
        }
    }
    if (!mediaType) {
        // don't have video camera return error
        NSLog(@"Capture.captureVideo: video mode not available.");
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_NOT_SUPPORTED];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        pickerController = nil;
    } else {
        pickerController.delegate = self;
        pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        pickerController.allowsEditing = NO;
        // iOS 3.0
        pickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];

        /*if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]){
            if (duration) {
                pickerController.videoMaximumDuration = [duration doubleValue];
            }
            //NSLog(@"pickerController.videoMaximumDuration = %f", pickerController.videoMaximumDuration);
        }*/

        // iOS 4.0
        if ([pickerController respondsToSelector:@selector(cameraCaptureMode)]) {
            pickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            pickerController.videoQuality = UIImagePickerControllerQualityTypeMedium;
            // pickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            // pickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        }
        
        // CDVImagePicker specific property
        pickerController.callbackId = callbackId;
        
        
        pickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

        if ([self.viewController respondsToSelector:@selector(presentViewController:::)]) {
            [self.viewController presentViewController:pickerController animated:YES completion:nil];
        } else {
            [self.viewController presentModalViewController:pickerController animated:YES];
        }
    }
}

- (void)processVideo:(NSDictionary*)params
{    
    NSURL* movieMediaURL = [params objectForKey:@"movieMediaURL"];
    NSString* moviePath = [movieMediaURL path];
    NSString* callbackId = [params valueForKey:@"callbackId"];
    
    UISaveVideoAtPathToSavedPhotosAlbum(moviePath, nil, nil, nil);
    
    // generate new mid for this video
    unsigned int mid = ( arc4random() % 100000000 ) + 100000000;
    
    AVAsset *avAsset = [AVURLAsset URLAssetWithURL:movieMediaURL options:nil];
        
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:avAsset];
    
    Float64 durationSeconds = CMTimeGetSeconds([avAsset duration]);
    CMTime midpoint = CMTimeMakeWithSeconds(durationSeconds/2.0, 600);
    
    NSError *error = nil;
    
    CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:nil error:&error];
    
    if (halfWayImage != NULL) {
        /*
         NSString *actualTimeString = (NSString *)CMTimeCopyDescription(NULL, actualTime);
         NSString *requestedTimeString = (NSString *)CMTimeCopyDescription(NULL, midpoint);
         NSLog(@"Got halfWayImage: Asked for %@, got %@", requestedTimeString, actualTimeString);
         */
        
        UIImage* image = [UIImage imageWithCGImage:halfWayImage];
        
        CGImageRelease(halfWayImage);
        
        CGSize destSize = CGSizeMake(233.0f, 175.0f);
        UIImage *thumb = [image fillSize:destSize];
        NSData* thumbData = UIImageJPEGRepresentation(thumb, 0.3);
        
        // write to temp directory and return URI
        NSString* docsPath = [NSTemporaryDirectory ()stringByStandardizingPath];  // use file system temporary directory
        NSError* err = nil;
        NSFileManager* fileMgr = [[NSFileManager alloc] init];
        
        // generate unique file name
        NSString* filePathThumb;
        do {
            filePathThumb = [NSString stringWithFormat:@"%@/wsi_video_still_%03d.jpg", docsPath, (rand() % 100000)];
        } while ([fileMgr fileExistsAtPath:filePathThumb]);
        
        
        if (![thumbData writeToFile:filePathThumb options:NSAtomicWrite error:&err]) {
            NSLog(@"Error saving thumb image");
        } else {
            NSDictionary* staticThumbDict = [self getMediaDictionaryFromPath:filePathThumb ofType:nil];
            NSMutableDictionary* thumbDict = [staticThumbDict mutableCopy];
            [thumbDict setValue:[NSString stringWithFormat:@"%i", mid] forKey:@"mid"];
            [thumbDict setValue:@"video" forKey:@"mediaType"];
            [thumbDict setValue:@"initialRecordInformer" forKey:@"typeOfPluginResult"];
            [thumbDict setValue:[thumbDict objectForKey:@"fullPath"] forKey:@"filePath"];
            [thumbDict setValue:[thumbDict objectForKey:@"fullPath"] forKey:@"filePathMedium"];
            [thumbDict setValue:[thumbDict objectForKey:@"fullPath"] forKey:@"filePathThumb"];
            
            NSArray* fileArray = [NSArray arrayWithObject:thumbDict];
            
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
            
            [result setKeepCallbackAsBool:YES];
            
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];

            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:moviePath forKey:@"filePath"];
            [params setValue:[NSNull null] forKey:@"filePathMedium"];
            [params setValue:[NSNull null] forKey:@"filePathThumb"];
            [params setValue:[NSString stringWithFormat:@"%i.MOV", mid] forKey:@"key"];
            [params setValue:[NSNull null] forKey:@"keyMedium"];
            [params setValue:[NSNull null] forKey:@"keyThumb"];
            [params setValue:[NSString stringWithFormat:@"%i", mid] forKey:@"mid"];
            [params setValue:@"video" forKey:@"mediaType"];
            [params setValue:(NSString*)callbackId forKey:@"callbackId"];
            
            [self performSelectorOnMainThread:@selector(processBackgroundThreadUpload:)
                                   withObject:params
                                waitUntilDone:NO];
        }
        
        
    } else {
        NSLog(@"halfWayImage was null");
        NSLog(@"%@", [error localizedDescription]);
        NSLog(@"%@", [error localizedFailureReason]);
        NSLog(@"%@", error);
    }
    
    return;
}

- (void)getMediaModes:(CDVInvokedUrlCommand*)command
{
    // NSString* callbackId = [arguments objectAtIndex:0];
    // NSMutableDictionary* imageModes = nil;
    NSArray* imageArray = nil;
    NSArray* movieArray = nil;
    NSArray* audioArray = nil;

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // there is a camera, find the modes
        // can get image/jpeg or image/png from camera

        /* can't find a way to get the default height and width and other info
         * for images/movies taken with UIImagePickerController
         */
        NSDictionary* jpg = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:0], kW3CMediaFormatHeight,
            [NSNumber numberWithInt:0], kW3CMediaFormatWidth,
            @"image/jpeg", kW3CMediaModeType,
            nil];
        NSDictionary* png = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:0], kW3CMediaFormatHeight,
            [NSNumber numberWithInt:0], kW3CMediaFormatWidth,
            @"image/png", kW3CMediaModeType,
            nil];
        imageArray = [NSArray arrayWithObjects:jpg, png, nil];

        if ([UIImagePickerController respondsToSelector:@selector(availableMediaTypesForSourceType:)]) {
            NSArray* types = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];

            if ([types containsObject:(NSString*)kUTTypeMovie]) {
                NSDictionary* mov = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:0], kW3CMediaFormatHeight,
                    [NSNumber numberWithInt:0], kW3CMediaFormatWidth,
                    @"video/quicktime", kW3CMediaModeType,
                    nil];
                movieArray = [NSArray arrayWithObject:mov];
            }
        }
    }
    NSDictionary* modes = [NSDictionary dictionaryWithObjectsAndKeys:
        imageArray ? (NSObject*)                          imageArray:[NSNull null], @"image",
        movieArray ? (NSObject*)                          movieArray:[NSNull null], @"video",
        audioArray ? (NSObject*)                          audioArray:[NSNull null], @"audio",
        nil];
    NSString* jsString = [NSString stringWithFormat:@"navigator.device.capture.setSupportedModes(%@);", [modes cdvjk_JSONString]];
    [self.commandDelegate evalJs:jsString];
}

- (void)getFormatData:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    // existence of fullPath checked on JS side
    NSString* fullPath = [command.arguments objectAtIndex:0];
    // mimeType could be null
    NSString* mimeType = nil;

    if ([command.arguments count] > 1) {
        mimeType = [command.arguments objectAtIndex:1];
    }
    BOOL bError = NO;
    CDVCaptureError errorCode = CAPTURE_INTERNAL_ERR;
    CDVPluginResult* result = nil;

    if (!mimeType || [mimeType isKindOfClass:[NSNull class]]) {
        // try to determine mime type if not provided
        id command = [self.commandDelegate getCommandInstance:@"File"];
        bError = !([command isKindOfClass:[CDVFile class]]);
        if (!bError) {
            CDVFile* cdvFile = (CDVFile*)command;
            mimeType = [cdvFile getMimeTypeFromPath:fullPath];
            if (!mimeType) {
                // can't do much without mimeType, return error
                bError = YES;
                errorCode = CAPTURE_INVALID_ARGUMENT;
            }
        }
    }
    if (!bError) {
        // create and initialize return dictionary
        NSMutableDictionary* formatData = [NSMutableDictionary dictionaryWithCapacity:5];
        [formatData setObject:[NSNull null] forKey:kW3CMediaFormatCodecs];
        [formatData setObject:[NSNumber numberWithInt:0] forKey:kW3CMediaFormatBitrate];
        [formatData setObject:[NSNumber numberWithInt:0] forKey:kW3CMediaFormatHeight];
        [formatData setObject:[NSNumber numberWithInt:0] forKey:kW3CMediaFormatWidth];
        [formatData setObject:[NSNumber numberWithInt:0] forKey:kW3CMediaFormatDuration];

        if ([mimeType rangeOfString:@"image/"].location != NSNotFound) {
            UIImage* image = [UIImage imageWithContentsOfFile:fullPath];
            if (image) {
                CGSize imgSize = [image size];
                [formatData setObject:[NSNumber numberWithInteger:imgSize.width] forKey:kW3CMediaFormatWidth];
                [formatData setObject:[NSNumber numberWithInteger:imgSize.height] forKey:kW3CMediaFormatHeight];
            }
        } else if (([mimeType rangeOfString:@"video/"].location != NSNotFound) && (NSClassFromString(@"AVURLAsset") != nil)) {
            NSURL* movieURL = [NSURL fileURLWithPath:fullPath];
            AVURLAsset* movieAsset = [[AVURLAsset alloc] initWithURL:movieURL options:nil];
            CMTime duration = [movieAsset duration];
            [formatData setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(duration)]  forKey:kW3CMediaFormatDuration];
            CGSize size = [movieAsset naturalSize];
            [formatData setObject:[NSNumber numberWithFloat:size.height] forKey:kW3CMediaFormatHeight];
            [formatData setObject:[NSNumber numberWithFloat:size.width] forKey:kW3CMediaFormatWidth];
            // not sure how to get codecs or bitrate???
            // AVMetadataItem
            // AudioFile
        } else if ([mimeType rangeOfString:@"audio/"].location != NSNotFound) {
            if (NSClassFromString(@"AVAudioPlayer") != nil) {
                NSURL* fileURL = [NSURL fileURLWithPath:fullPath];
                NSError* err = nil;

                AVAudioPlayer* avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&err];
                if (!err) {
                    // get the data
                    [formatData setObject:[NSNumber numberWithDouble:[avPlayer duration]] forKey:kW3CMediaFormatDuration];
                    if ([avPlayer respondsToSelector:@selector(settings)]) {
                        NSDictionary* info = [avPlayer settings];
                        NSNumber* bitRate = [info objectForKey:AVEncoderBitRateKey];
                        if (bitRate) {
                            [formatData setObject:bitRate forKey:kW3CMediaFormatBitrate];
                        }
                    }
                } // else leave data init'ed to 0
            }
        }
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:formatData];
        // NSLog(@"getFormatData: %@", [formatData description]);
    }
    if (bError) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:errorCode];
    }
    if (result) {
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}

- (NSDictionary*)getMediaDictionaryFromPath:(NSString*)fullPath ofType:(NSString*)type
{
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSMutableDictionary* fileDict = [NSMutableDictionary dictionaryWithCapacity:5];

    [fileDict setObject:[fullPath lastPathComponent] forKey:@"name"];
    [fileDict setObject:fullPath forKey:@"fullPath"];
    // determine type
    if (!type) {
        id command = [self.commandDelegate getCommandInstance:@"File"];
        if ([command isKindOfClass:[CDVFile class]]) {
            CDVFile* cdvFile = (CDVFile*)command;
            NSString* mimeType = [cdvFile getMimeTypeFromPath:fullPath];
            [fileDict setObject:(mimeType != nil ? (NSObject*)mimeType:[NSNull null]) forKey:@"type"];
        }
    }
    NSDictionary* fileAttrs = [fileMgr attributesOfItemAtPath:fullPath error:nil];
    [fileDict setObject:[NSNumber numberWithUnsignedLongLong:[fileAttrs fileSize]] forKey:@"size"];
    NSDate* modDate = [fileAttrs fileModificationDate];
    NSNumber* msDate = [NSNumber numberWithDouble:[modDate timeIntervalSince1970] * 1000];
    [fileDict setObject:msDate forKey:@"lastModifiedDate"];

    return fileDict;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
    // older api calls new one
    [self imagePickerController:picker didFinishPickingMediaWithInfo:editingInfo];
}

/* Called when image/movie is finished recording.
 * Calls success or error code as appropriate
 * if successful, result  contains an array (with just one entry since can only get one image unless build own camera UI) of MediaFile object representing the image
 *      name
 *      fullPath
 *      type
 *      lastModifiedDate
 *      size
 */
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    CDVImagePicker* cameraPicker = (CDVImagePicker*)picker;
    NSString* callbackId = cameraPicker.callbackId;

    if ([picker respondsToSelector:@selector(presentingViewController)]) {
        [[picker presentingViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [[picker parentViewController] dismissModalViewControllerAnimated:YES];
    }

    CDVPluginResult* result = nil;

    UIImage* image = nil;
    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (!mediaType || [mediaType isEqualToString:(NSString*)kUTTypeImage]) {
        // mediaType is nil then only option is UIImagePickerControllerOriginalImage
        if ([UIImagePickerController respondsToSelector:@selector(allowsEditing)] &&
            (cameraPicker.allowsEditing && [info objectForKey:UIImagePickerControllerEditedImage])) {
            image = [info objectForKey:UIImagePickerControllerEditedImage];
        } else {
            image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
    }
    if (image != nil) {
        // mediaType was image
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:image forKey:@"image"];
        [params setValue:cameraPicker.mimeType forKey:@"type"];
        [params setValue:callbackId forKey:@"callbackId"];
        [self performSelectorInBackground:@selector(processImage:)
                               withObject:params];
        //result = [self processImage:image type:cameraPicker.mimeType forCallbackId:callbackId];
        //[result setKeepCallbackAsBool:YES];
        return;
    } else if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]) {
        // process video
        NSURL* movieMediaURL = [info objectForKey:UIImagePickerControllerMediaURL];
        if (movieMediaURL) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:movieMediaURL forKey:@"movieMediaURL"];
            [params setValue:callbackId forKey:@"callbackId"];
            [self performSelectorInBackground:@selector(processVideo:)
                                   withObject:params];
            //result = [self processVideo:moviePath forCallbackId:callbackId];
            //[result setKeepCallbackAsBool:YES];
            return;
        }
    }
    if (!result) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_INTERNAL_ERR];
    }
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    pickerController = nil;
}
        
- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    CDVImagePicker* cameraPicker = (CDVImagePicker*)picker;
    NSString* callbackId = cameraPicker.callbackId;

    if ([picker respondsToSelector:@selector(presentingViewController)]) {
        [[picker presentingViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [[picker parentViewController] dismissModalViewControllerAnimated:YES];
    }

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_NO_MEDIA_FILES];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    pickerController = nil;
}

@end

@implementation CDVAudioNavigationController

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (NSUInteger)supportedInterfaceOrientations
{
    // delegate to CVDAudioRecorderViewController
    return [self.topViewController supportedInterfaceOrientations];
}
#endif

@end

@implementation CDVAudioRecorderViewController
@synthesize errorCode, callbackId, duration, captureCommand, doneButton, recordingView, recordButton, recordImage, stopRecordImage, timerLabel, avRecorder, avSession, pluginResult, timer, isTimed;

- (NSString*)resolveImageResource:(NSString*)resource
{
    NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
    BOOL isLessThaniOS4 = ([systemVersion compare:@"4.0" options:NSNumericSearch] == NSOrderedAscending);

    // the iPad image (nor retina) differentiation code was not in 3.x, and we have to explicitly set the path
    // if user wants iPhone only app to run on iPad they must remove *~ipad.* images from capture.bundle
    if (isLessThaniOS4) {
        NSString* iPadResource = [NSString stringWithFormat:@"%@~ipad.png", resource];
        if (CDV_IsIPad() && [UIImage imageNamed:iPadResource]) {
            return iPadResource;
        } else {
            return [NSString stringWithFormat:@"%@.png", resource];
        }
    }

    return resource;
}

- (id)initWithCommand:(CDVCapture*)theCommand duration:(NSNumber*)theDuration callbackId:(NSString*)theCallbackId
{
    if ((self = [super init])) {
        self.captureCommand = theCommand;
        self.duration = theDuration;
        self.callbackId = theCallbackId;
        self.errorCode = CAPTURE_NO_MEDIA_FILES;
        self.isTimed = self.duration != nil;

        return self;
    }

    return nil;
}

- (void)loadView
{
    // create view and display
    CGRect viewRect = [[UIScreen mainScreen] applicationFrame];
    UIView* tmp = [[UIView alloc] initWithFrame:viewRect];

    // make backgrounds
    NSString* microphoneResource = @"Capture.bundle/microphone";

    if (CDV_IsIPhone5()) {
        microphoneResource = @"Capture.bundle/microphone-568h";
    }

    UIImage* microphone = [UIImage imageNamed:[self resolveImageResource:microphoneResource]];
    UIView* microphoneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewRect.size.width, microphone.size.height)];
    [microphoneView setBackgroundColor:[UIColor colorWithPatternImage:microphone]];
    [microphoneView setUserInteractionEnabled:NO];
    [microphoneView setIsAccessibilityElement:NO];
    [tmp addSubview:microphoneView];

    // add bottom bar view
    UIImage* grayBkg = [UIImage imageNamed:[self resolveImageResource:@"Capture.bundle/controls_bg"]];
    UIView* controls = [[UIView alloc] initWithFrame:CGRectMake(0, microphone.size.height, viewRect.size.width, grayBkg.size.height)];
    [controls setBackgroundColor:[UIColor colorWithPatternImage:grayBkg]];
    [controls setUserInteractionEnabled:NO];
    [controls setIsAccessibilityElement:NO];
    [tmp addSubview:controls];

    // make red recording background view
    UIImage* recordingBkg = [UIImage imageNamed:[self resolveImageResource:@"Capture.bundle/recording_bg"]];
    UIColor* background = [UIColor colorWithPatternImage:recordingBkg];
    self.recordingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewRect.size.width, recordingBkg.size.height)];
    [self.recordingView setBackgroundColor:background];
    [self.recordingView setHidden:YES];
    [self.recordingView setUserInteractionEnabled:NO];
    [self.recordingView setIsAccessibilityElement:NO];
    [tmp addSubview:self.recordingView];

    // add label
    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewRect.size.width, recordingBkg.size.height)];
    // timerLabel.autoresizingMask = reSizeMask;
    [self.timerLabel setBackgroundColor:[UIColor clearColor]];
    [self.timerLabel setTextColor:[UIColor whiteColor]];
    [self.timerLabel setTextAlignment:UITextAlignmentCenter];
    [self.timerLabel setText:@"0:00"];
    [self.timerLabel setAccessibilityHint:NSLocalizedString(@"recorded time in minutes and seconds", nil)];
    self.timerLabel.accessibilityTraits |= UIAccessibilityTraitUpdatesFrequently;
    self.timerLabel.accessibilityTraits &= ~UIAccessibilityTraitStaticText;
    [tmp addSubview:self.timerLabel];

    // Add record button

    self.recordImage = [UIImage imageNamed:[self resolveImageResource:@"Capture.bundle/record_button"]];
    self.stopRecordImage = [UIImage imageNamed:[self resolveImageResource:@"Capture.bundle/stop_button"]];
    self.recordButton.accessibilityTraits |= [self accessibilityTraits];
    self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake((viewRect.size.width - recordImage.size.width) / 2, (microphone.size.height + (grayBkg.size.height - recordImage.size.height) / 2), recordImage.size.width, recordImage.size.height)];
    [self.recordButton setAccessibilityLabel:NSLocalizedString(@"toggle audio recording", nil)];
    [self.recordButton setImage:recordImage forState:UIControlStateNormal];
    [self.recordButton addTarget:self action:@selector(processButton:) forControlEvents:UIControlEventTouchUpInside];
    [tmp addSubview:recordButton];

    // make and add done button to navigation bar
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAudioView:)];
    [self.doneButton setStyle:UIBarButtonItemStyleDone];
    self.navigationItem.rightBarButtonItem = self.doneButton;

    [self setView:tmp];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    NSError* error = nil;

    if (self.avSession == nil) {
        // create audio session
        self.avSession = [AVAudioSession sharedInstance];
        if (error) {
            // return error if can't create recording audio session
            NSLog(@"error creating audio session: %@", [[error userInfo] description]);
            self.errorCode = CAPTURE_INTERNAL_ERR;
            [self dismissAudioView:nil];
        }
    }

    // create file to record to in temporary dir

    NSString* docsPath = [NSTemporaryDirectory ()stringByStandardizingPath];  // use file system temporary directory
    NSError* err = nil;
    NSFileManager* fileMgr = [[NSFileManager alloc] init];

    // generate unique file name
    NSString* filePath;
    int i = 1;
    do {
        filePath = [NSString stringWithFormat:@"%@/audio_%03d.wav", docsPath, i++];
    } while ([fileMgr fileExistsAtPath:filePath]);

    NSURL* fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];

    // create AVAudioPlayer
    self.avRecorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:nil error:&err];
    if (err) {
        NSLog(@"Failed to initialize AVAudioRecorder: %@\n", [err localizedDescription]);
        self.avRecorder = nil;
        // return error
        self.errorCode = CAPTURE_INTERNAL_ERR;
        [self dismissAudioView:nil];
    } else {
        self.avRecorder.delegate = self;
        [self.avRecorder prepareToRecord];
        self.recordButton.enabled = YES;
        self.doneButton.enabled = YES;
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger orientation = UIInterfaceOrientationMaskPortrait; // must support portrait
    NSUInteger supported = [captureCommand.viewController supportedInterfaceOrientations];

    orientation = orientation | (supported & UIInterfaceOrientationMaskPortraitUpsideDown);
    return orientation;
}
#endif

- (void)viewDidUnload
{
    [self setView:nil];
    [self.captureCommand setInUse:NO];
}

- (void)processButton:(id)sender
{
    if (self.avRecorder.recording) {
        // stop recording
        [self.avRecorder stop];
        self.isTimed = NO;  // recording was stopped via button so reset isTimed
        // view cleanup will occur in audioRecordingDidFinishRecording
    } else {
        // begin recording
        [self.recordButton setImage:stopRecordImage forState:UIControlStateNormal];
        self.recordButton.accessibilityTraits &= ~[self accessibilityTraits];
        [self.recordingView setHidden:NO];
        NSError* error = nil;
        [self.avSession setCategory:AVAudioSessionCategoryRecord error:&error];
        [self.avSession setActive:YES error:&error];
        if (error) {
            // can't continue without active audio session
            self.errorCode = CAPTURE_INTERNAL_ERR;
            [self dismissAudioView:nil];
        } else {
            if (self.duration) {
                self.isTimed = true;
                [self.avRecorder recordForDuration:[duration doubleValue]];
            } else {
                [self.avRecorder record];
            }
            [self.timerLabel setText:@"0.00"];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
            self.doneButton.enabled = NO;
        }
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}

/*
 * helper method to clean up when stop recording
 */
- (void)stopRecordingCleanup
{
    if (self.avRecorder.recording) {
        [self.avRecorder stop];
    }
    [self.recordButton setImage:recordImage forState:UIControlStateNormal];
    self.recordButton.accessibilityTraits |= [self accessibilityTraits];
    [self.recordingView setHidden:YES];
    self.doneButton.enabled = YES;
    if (self.avSession) {
        // deactivate session so sounds can come through
        [self.avSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [self.avSession setActive:NO error:nil];
    }
    if (self.duration && self.isTimed) {
        // VoiceOver announcement so user knows timed recording has finished
        BOOL isUIAccessibilityAnnouncementNotification = (&UIAccessibilityAnnouncementNotification != NULL);
        if (isUIAccessibilityAnnouncementNotification) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500ull * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                    UIAccessibilityPostNotification (UIAccessibilityAnnouncementNotification, NSLocalizedString (@"timed recording complete", nil));
                });
        }
    } else {
        // issue a layout notification change so that VO will reannounce the button label when recording completes
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}

- (void)dismissAudioView:(id)sender
{
    // called when done button pressed or when error condition to do cleanup and remove view
    if ([self.captureCommand.viewController.modalViewController respondsToSelector:@selector(presentingViewController)]) {
        [[self.captureCommand.viewController.modalViewController presentingViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [[self.captureCommand.viewController.modalViewController parentViewController] dismissModalViewControllerAnimated:YES];
    }

    if (!self.pluginResult) {
        // return error
        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:self.errorCode];
    }

    self.avRecorder = nil;
    [self.avSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [self.avSession setActive:NO error:nil];
    [self.captureCommand setInUse:NO];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    // return result
    [self.captureCommand.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)updateTime
{
    // update the label with the elapsed time
    [self.timerLabel setText:[self formatTime:self.avRecorder.currentTime]];
}

- (NSString*)formatTime:(int)interval
{
    // is this format universal?
    int secs = interval % 60;
    int min = interval / 60;

    if (interval < 60) {
        return [NSString stringWithFormat:@"0:%02d", interval];
    } else {
        return [NSString stringWithFormat:@"%d:%02d", min, secs];
    }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder*)recorder successfully:(BOOL)flag
{
    // may be called when timed audio finishes - need to stop time and reset buttons
    [self.timer invalidate];
    [self stopRecordingCleanup];

    // generate success result
    if (flag) {
        NSString* filePath = [avRecorder.url path];
        // NSLog(@"filePath: %@", filePath);
        NSDictionary* fileDict = [captureCommand getMediaDictionaryFromPath:filePath ofType:@"audio/wav"];
        NSArray* fileArray = [NSArray arrayWithObject:fileDict];

        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
    } else {
        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageToErrorObject:CAPTURE_INTERNAL_ERR];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder*)recorder error:(NSError*)error
{
    [self.timer invalidate];
    [self stopRecordingCleanup];

    NSLog(@"error recording audio");
    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageToErrorObject:CAPTURE_INTERNAL_ERR];
    [self dismissAudioView:nil];
}

@end
