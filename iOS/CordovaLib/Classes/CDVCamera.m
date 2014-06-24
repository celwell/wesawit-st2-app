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

#import "CDVCamera.h"
#import "NSArray+Comparisons.h"
#import "NSData+Base64.h"
#import "NSDictionary+Extensions.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "UIImage+fixOrientation.h"

#import "Geometry.h"
#import "UIImage-Utilities.h"
#import "Orientation.h"

#define CDV_PHOTO_PREFIX @"cdv_photo_"

static NSSet* org_apache_cordova_validArrowDirections;

@interface CDVCamera ()

@property (readwrite, assign) BOOL hasPendingOperation;

@end

@implementation CDVCamera

+ (void)initialize
{
    org_apache_cordova_validArrowDirections = [[NSSet alloc] initWithObjects:[NSNumber numberWithInt:UIPopoverArrowDirectionUp], [NSNumber numberWithInt:UIPopoverArrowDirectionDown], [NSNumber numberWithInt:UIPopoverArrowDirectionLeft], [NSNumber numberWithInt:UIPopoverArrowDirectionRight], [NSNumber numberWithInt:UIPopoverArrowDirectionAny], nil];
}

@synthesize hasPendingOperation, pickerController;

@synthesize s3;
@synthesize tm;
@synthesize backgroundTaskId;

- (BOOL)popoverSupported
{
    return (NSClassFromString(@"UIPopoverController") != nil) &&
           (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

/*  takePicture arguments:
 * INDEX   ARGUMENT
 *  0       quality
 *  1       destination type
 *  2       source type
 *  3       targetWidth
 *  4       targetHeight
 *  5       encodingType
 *  6       mediaType
 *  7       allowsEdit
 *  8       correctOrientation
 *  9       saveToPhotoAlbum
 */
- (void)takePicture:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSArray* arguments = command.arguments;

    self.hasPendingOperation = NO;

    NSString* sourceTypeString = [arguments objectAtIndex:2];
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera; // default
    if (sourceTypeString != nil) {
        sourceType = (UIImagePickerControllerSourceType)[sourceTypeString intValue];
    }

    bool hasCamera = [UIImagePickerController isSourceTypeAvailable:sourceType];
    if (!hasCamera) {
        NSLog(@"Camera.getPicture: source type %d not available.", sourceType);
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no camera available"];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        return;
    }

    bool allowEdit = [[arguments objectAtIndex:7] boolValue];
    NSNumber* targetWidth = [arguments objectAtIndex:3];
    NSNumber* targetHeight = [arguments objectAtIndex:4];
    NSNumber* mediaValue = [arguments objectAtIndex:6];
    CDVMediaType mediaType = (mediaValue) ? [mediaValue intValue] : MediaTypePicture;

    CGSize targetSize = CGSizeMake(0, 0);
    if ((targetWidth != nil) && (targetHeight != nil)) {
        targetSize = CGSizeMake([targetWidth floatValue], [targetHeight floatValue]);
    }

    CDVCameraPicker* cameraPicker = [[CDVCameraPicker alloc] init];
    self.pickerController = cameraPicker;

    cameraPicker.delegate = self;
    cameraPicker.sourceType = sourceType;
    cameraPicker.allowsEditing = allowEdit; // THIS IS ALL IT TAKES FOR CROPPING - jm
    cameraPicker.callbackId = callbackId;
    cameraPicker.targetSize = targetSize;
    cameraPicker.cropToSize = NO;
    // we need to capture this state for memory warnings that dealloc this object
    cameraPicker.webView = self.webView;
    cameraPicker.popoverSupported = [self popoverSupported];

    cameraPicker.correctOrientation = [[arguments objectAtIndex:8] boolValue];
    cameraPicker.saveToPhotoAlbum = [[arguments objectAtIndex:9] boolValue];
    
    cameraPicker.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    cameraPicker.encodingType = ([arguments objectAtIndex:5]) ? [[arguments objectAtIndex:5] intValue] : EncodingTypeJPEG;

    cameraPicker.quality = ([arguments objectAtIndex:0]) ? [[arguments objectAtIndex:0] intValue] : 50;
    cameraPicker.returnType = ([arguments objectAtIndex:1]) ? [[arguments objectAtIndex:1] intValue] : DestinationTypeFileUri;
    

    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        // we only allow taking pictures (no video) in this api
        cameraPicker.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeImage, nil];
    } else if (mediaType == MediaTypeAll) {
        cameraPicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    } else {
        NSArray* mediaArray = [NSArray arrayWithObjects:(NSString*)(mediaType == MediaTypeVideo ? kUTTypeMovie:kUTTypeImage), nil];
        cameraPicker.mediaTypes = mediaArray;
    }

    if ([self popoverSupported] && (sourceType != UIImagePickerControllerSourceTypeCamera)) {
        if (cameraPicker.popoverController == nil) {
            cameraPicker.popoverController = [[NSClassFromString (@"UIPopoverController")alloc] initWithContentViewController:cameraPicker];
        }
        int x = 0;
        int y = 32;
        int width = 320;
        int height = 480;
        UIPopoverArrowDirection arrowDirection = UIPopoverArrowDirectionAny;
        NSDictionary* options = [command.arguments objectAtIndex:10 withDefault:nil];
        if (options) {
            x = [options integerValueForKey:@"x" defaultValue:0];
            y = [options integerValueForKey:@"y" defaultValue:32];
            width = [options integerValueForKey:@"width" defaultValue:320];
            height = [options integerValueForKey:@"height" defaultValue:480];
            arrowDirection = [options integerValueForKey:@"arrowDir" defaultValue:UIPopoverArrowDirectionAny];
            if (![org_apache_cordova_validArrowDirections containsObject:[NSNumber numberWithInt:arrowDirection]]) {
                arrowDirection = UIPopoverArrowDirectionAny;
            }
        }

        cameraPicker.popoverController.delegate = self;
        [cameraPicker.popoverController presentPopoverFromRect:CGRectMake(x, y, width, height)
                                                        inView:[self.webView superview]
                                      permittedArrowDirections:arrowDirection
                                                      animated:NO];
    } else {
        if ([self.viewController respondsToSelector:@selector(presentViewController:::)]) {
            [self.viewController presentViewController:cameraPicker animated:YES completion:nil];
        } else {
            [self.viewController presentModalViewController:cameraPicker animated:YES];
        }
    }
    self.hasPendingOperation = YES;
}

- (void)cleanup:(CDVInvokedUrlCommand*)command
{
    // empty the tmp directory
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSError* err = nil;
    BOOL hasErrors = NO;

    // clear contents of NSTemporaryDirectory
    NSString* tempDirectoryPath = NSTemporaryDirectory();
    NSDirectoryEnumerator* directoryEnumerator = [fileMgr enumeratorAtPath:tempDirectoryPath];
    NSString* fileName = nil;
    BOOL result;

    while ((fileName = [directoryEnumerator nextObject])) {
        // only delete the files we created
        if (![fileName hasPrefix:CDV_PHOTO_PREFIX]) {
            continue;
        }
        NSString* filePath = [tempDirectoryPath stringByAppendingPathComponent:fileName];
        result = [fileMgr removeItemAtPath:filePath error:&err];
        if (!result && err) {
            NSLog(@"Failed to delete: %@ (error: %@)", filePath, err);
            hasErrors = YES;
        }
    }

    CDVPluginResult* pluginResult;
    if (hasErrors) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:@"One or more files failed to be deleted."];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)popoverControllerDidDismissPopover:(id)popoverController
{
    // [ self imagePickerControllerDidCancel:self.pickerController ];	'
    UIPopoverController* pc = (UIPopoverController*)popoverController;

    [pc dismissPopoverAnimated:YES];
    pc.delegate = nil;
    if (self.pickerController && self.pickerController.callbackId && self.pickerController.popoverController) {
        self.pickerController.popoverController = nil;
        NSString* callbackId = self.pickerController.callbackId;
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no image selected"];   // error callback expects string ATM
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
    self.hasPendingOperation = NO;
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
    [resultParams setValue:callbackId forKey:@"callbackId"];
    [resultParams setValue:type forKey:@"uploadType"];
    [resultParams setValue:@"progress" forKey:@"typeOfPluginResult"];
    [resultParams setValue:[NSString stringWithFormat:@"%i", totalBytesWritten] forKey:@"totalBytesWritten"];
    [resultParams setValue:[NSString stringWithFormat:@"%i", totalBytesExpectedToWrite] forKey:@"totalBytesExpectedToWrite"];
    
    NSArray* resultArray = [NSArray arrayWithObject:resultParams];
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
    [resultParams setValue:callbackId forKey:@"callbackId"];
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
    [resultParams setValue:callbackId forKey:@"callbackId"];
    
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
 * IN:
 *  UIImage* image - the UIImage data returned from the camera
 *  NSString* callbackId
 */
- (void)processImage:(NSDictionary*)params
{
    UIImage* image = [[params objectForKey:@"image"] fixOrientation];
    NSString* callbackId = [params valueForKey:@"callbackId"];
    
    CDVPluginResult* result = nil;
    
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
                
                /* this is the only difference between the processImage function in CDVCapture.m and here */
                if ([params valueForKey:@"metadataJson"] != nil) {
                    [fileDict setValue:[params valueForKey:@"metadataJson"] forKey:@"metadataJson"];
                }
                /* end part that's not the same */
                
                NSArray* fileArray = [NSArray arrayWithObject:fileDict];
                
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
                [result setKeepCallbackAsBool:YES];
                
                [self.commandDelegate sendPluginResult:result callbackId:callbackId];
                // start uploading them
                
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


- (void)processVideo:(NSDictionary*)params
{
    NSLog(@"Inside processVideo function #1");
    
    NSURL* movieMediaURL = [params objectForKey:@"movieMediaURL"];
    NSString* moviePath = [movieMediaURL path];
    NSString* callbackId = [params valueForKey:@"callbackId"];
    
    NSLog(@"moviePath: %@", moviePath);
    
    // generate new mid for this video
    unsigned int mid = ( arc4random() % 100000000 ) + 100000000;
    
    AVAsset *avAsset = [AVURLAsset URLAssetWithURL:movieMediaURL options:nil];
    
    NSLog(@"Inside processVideo function #2");
    
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
        
        NSLog(@"Inside halfwayImage conditional");
        
        UIImage* image = [UIImage imageWithCGImage:halfWayImage];
        
        CGImageRelease(halfWayImage);
        
        CGSize destSize = CGSizeMake(233.0f, 175.0f);
        UIImage *thumb = [image fillSize:destSize];
        NSData* thumbData = UIImageJPEGRepresentation(thumb, 0.3);
        
        NSLog(@"TimeSpot #v1E");
        
        // write to temp directory and return URI
        NSString* docsPath = [NSTemporaryDirectory ()stringByStandardizingPath];  // use file system temporary directory
        NSError* err = nil;
        NSFileManager* fileMgr = [[NSFileManager alloc] init];
        
        NSLog(@"TimeSpot #v1F");
        
        // generate unique file name
        NSString* filePathThumb;
        do {
            filePathThumb = [NSString stringWithFormat:@"%@/wsi_video_still_%03d.jpg", docsPath, (rand() % 100000)];
        } while ([fileMgr fileExistsAtPath:filePathThumb]);
        
        
        if (![thumbData writeToFile:filePathThumb options:NSAtomicWrite error:&err]) {
            NSLog(@"Error saving thumb image");
        } else {
            NSLog(@"TimeSpot #v1I");
            NSDictionary* staticThumbDict = [self getMediaDictionaryFromPath:filePathThumb ofType:nil];
            NSMutableDictionary* thumbDict = [staticThumbDict mutableCopy];
            [thumbDict setValue:[NSString stringWithFormat:@"%i", mid] forKey:@"mid"];
            [thumbDict setValue:@"video" forKey:@"mediaType"];
            [thumbDict setValue:@"initialRecordInformer" forKey:@"typeOfPluginResult"];
            if ([params valueForKey:@"metadataJson"] != nil) {
                [thumbDict setValue:[params valueForKey:@"metadataJson"] forKey:@"metadataJson"];
            }
            [thumbDict setValue:[thumbDict objectForKey:@"fullPath"] forKey:@"filePathThumb"];
                
            NSArray* fileArray = [NSArray arrayWithObject:thumbDict];
            
            NSLog(@"fileArray Contents: %@", fileArray);
            
            
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
            
            NSLog(@"video->params Contents: %@", params);
            
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



-(NSString *)getUTCDate:(NSString *)localDateStr
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    NSDate *localDate = [dateFormatter dateFromString:localDateStr];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    NSString *utcDateStr = [dateFormatter stringFromDate:localDate];
    return utcDateStr;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    CDVCameraPicker* cameraPicker = (CDVCameraPicker*)picker;

    if (cameraPicker.popoverSupported && (cameraPicker.popoverController != nil)) {
        [cameraPicker.popoverController dismissPopoverAnimated:YES];
        cameraPicker.popoverController.delegate = nil;
        cameraPicker.popoverController = nil;
    } else {
        if ([cameraPicker respondsToSelector:@selector(presentingViewController)]) {
            [[cameraPicker presentingViewController] dismissModalViewControllerAnimated:YES];
        } else {
            [[cameraPicker parentViewController] dismissModalViewControllerAnimated:YES];
        }
    }

    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL]
        resultBlock:^(ALAsset *asset) {
            CDVPluginResult* result = nil;
            
            NSMutableDictionary *assetMetadata = [[[asset defaultRepresentation] metadata] mutableCopy];
            CLLocation *assetLocation = [asset valueForProperty:ALAssetPropertyLocation];
            NSDictionary *gpsData = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithDouble:[assetLocation coordinate].longitude], @"lng", [NSNumber numberWithDouble:[assetLocation coordinate].latitude], @"lat", nil];
            [assetMetadata setObject:gpsData forKey:@"locationData"];
            
            NSString *dateTimeOriginal = [[assetMetadata objectForKey:@"{Exif}"] objectForKey:@"DateTimeOriginal"];
            NSString *dateTimeDigitized = [[assetMetadata objectForKey:@"{Exif}"] objectForKey:@"DateTimeDigitized"];
            if (dateTimeOriginal != nil) {
                [[assetMetadata objectForKey:@"{Exif}"] setObject:[self getUTCDate:dateTimeOriginal] forKey:@"DateTimeOriginal"];
            }
            if (dateTimeDigitized != nil) {
                [[assetMetadata objectForKey:@"{Exif}"] setObject:[self getUTCDate:dateTimeDigitized] forKey:@"DateTimeDigitized"];
            }
            
            
            NSError *jsonParseError;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:assetMetadata
                                    options:0
                                    error:&jsonParseError
            ];
            NSString* metadata = nil;
            if (!jsonData) {
                NSLog(@"JSON error: %@", jsonParseError);
            } else {
                metadata = [[NSString alloc] initWithData:jsonData
                                                  encoding:NSUTF8StringEncoding];
            }
            
            
            NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
            // IMAGE TYPE
            if ([mediaType isEqualToString:(NSString*)kUTTypeImage]) {
                // process image
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[info objectForKey:UIImagePickerControllerOriginalImage] forKey:@"image"];
                [params setValue:cameraPicker.callbackId forKey:@"callbackId"];
                [params setValue:metadata forKey:@"metadataJson"];
                [self performSelectorInBackground:@selector(processImage:)
                                           withObject:params];
                return;
            }
            // NOT IMAGE TYPE (MOVIE)
            else {
                // process video
                NSURL* movieMediaURL = [info objectForKey:UIImagePickerControllerMediaURL];
                NSLog(@"%@", movieMediaURL);
                if (movieMediaURL) {
                    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:movieMediaURL forKey:@"movieMediaURL"];
                    [params setValue:cameraPicker.callbackId forKey:@"callbackId"];
                    [params setValue:metadata forKey:@"metadataJson"];
                    [self performSelectorInBackground:@selector(processVideo:)
                                           withObject:params];
                    return;
                }

            }
            
            if (result) {
                [self.commandDelegate sendPluginResult:result callbackId:cameraPicker.callbackId];
            }
        }
        failureBlock:^(NSError *error) {
            NSLog(@"couldn't get asset: %@", error);
        }
     ];

    self.hasPendingOperation = NO;
    self.pickerController = nil;
}

// older api calls newer didFinishPickingMediaWithInfo
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
    NSDictionary* imageInfo = [NSDictionary dictionaryWithObject:image forKey:UIImagePickerControllerOriginalImage];

    [self imagePickerController:picker didFinishPickingMediaWithInfo:imageInfo];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    CDVCameraPicker* cameraPicker = (CDVCameraPicker*)picker;

    if ([cameraPicker respondsToSelector:@selector(presentingViewController)]) {
        [[cameraPicker presentingViewController] dismissModalViewControllerAnimated:NO];
    } else {
        [[cameraPicker parentViewController] dismissModalViewControllerAnimated:NO];
    }
    // popoverControllerDidDismissPopover:(id)popoverController is called if popover is cancelled

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no image selected"];   // error callback expects string ATM
    [self.commandDelegate sendPluginResult:result callbackId:cameraPicker.callbackId];

    self.hasPendingOperation = NO;
    self.pickerController = nil;
}

- (UIImage*)imageByScalingAndCroppingForSize:(UIImage*)anImage toSize:(CGSize)targetSize
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);

    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        } else {
            scaleFactor = heightFactor; // scale to fit width
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;

        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }

    UIGraphicsBeginImageContext(targetSize); // this will crop

    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;

    [sourceImage drawInRect:thumbnailRect];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }

    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)imageCorrectedForCaptureOrientation:(UIImage*)anImage
{
    float rotation_radians = 0;
    bool perpendicular = false;

    switch ([anImage imageOrientation]) {
        case UIImageOrientationUp :
            rotation_radians = 0.0;
            break;

        case UIImageOrientationDown :
            rotation_radians = M_PI; // don't be scared of radians, if you're reading this, you're good at math
            break;

        case UIImageOrientationRight:
            rotation_radians = M_PI_2;
            perpendicular = true;
            break;

        case UIImageOrientationLeft:
            rotation_radians = -M_PI_2;
            perpendicular = true;
            break;

        default:
            break;
    }

    UIGraphicsBeginImageContext(CGSizeMake(anImage.size.width, anImage.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Rotate around the center point
    CGContextTranslateCTM(context, anImage.size.width / 2, anImage.size.height / 2);
    CGContextRotateCTM(context, rotation_radians);

    CGContextScaleCTM(context, 1.0, -1.0);
    float width = perpendicular ? anImage.size.height : anImage.size.width;
    float height = perpendicular ? anImage.size.width : anImage.size.height;
    CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [anImage CGImage]);

    // Move the origin back since the rotation might've change it (if its 90 degrees)
    if (perpendicular) {
        CGContextTranslateCTM(context, -anImage.size.height / 2, -anImage.size.width / 2);
    }

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;

    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(MIN(width * scaleFactor, targetWidth), MIN(height * scaleFactor, targetHeight));
    }

    UIGraphicsBeginImageContext(scaledSize); // this will resize

    [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }

    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)postImage:(UIImage*)anImage withFilename:(NSString*)filename toUrl:(NSURL*)url
{
    self.hasPendingOperation = YES;

    NSString* boundary = @"----BOUNDARY_IS_I";

    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];

    NSString* contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [req setValue:contentType forHTTPHeaderField:@"Content-type"];

    NSData* imageData = UIImagePNGRepresentation(anImage);

    // adding the body
    NSMutableData* postBody = [NSMutableData data];

    // first parameter an image
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"upload\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:imageData];

    //	// second parameter information
    //	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //	[postBody appendData:[@"Content-Disposition: form-data; name=\"some_other_name\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    //	[postBody appendData:[@"some_other_value" dataUsingEncoding:NSUTF8StringEncoding]];
    //	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [req setHTTPBody:postBody];

    NSURLResponse* response;
    NSError* error;
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];

    //  NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    //	NSString * resultStr =  [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];

    self.hasPendingOperation = NO;
}

@end

@implementation CDVCameraPicker

@synthesize quality, postUrl;
@synthesize returnType;
@synthesize callbackId;
@synthesize popoverController;
@synthesize targetSize;
@synthesize correctOrientation;
@synthesize saveToPhotoAlbum;
@synthesize encodingType;
@synthesize cropToSize;
@synthesize webView;
@synthesize popoverSupported;

@end
