//
//  VideoCaptureViewController.m
//  CheckVideoRecording
//
//  Created by Vishwanath on 10/11/14.
//  Copyright (c) 2014 Vishwanath. All rights reserved.
//

#import "VideoCaptureViewController.h"

@interface VideoCaptureViewController ()

@end

@implementation VideoCaptureViewController
@synthesize PreviewLayer;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//********** VIEW DID LOAD **********
- (void)viewDidLoad {
    [super viewDidLoad];
    [self captureVideo];
}

- (void)captureVideo {
    CaptureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (VideoDevice) {
        NSError *error;
        VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
        if (!error) {
            if ([CaptureSession canAddInput:VideoInputDevice])
                [CaptureSession addInput:VideoInputDevice];
            else
                NSLog(@"Not able to add video input");
        }
        else {
            NSLog(@"not able to create video input");
        }
    }
    else {
        NSLog(@"not able to create video capture device");
    }
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput) {
        [CaptureSession addInput:audioInput];
    }
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:CaptureSession]];
    MovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 TotalSeconds = 60;			//Total seconds
    int32_t preferredTimeScale = 30;	//Frames per second
    //maximum duration
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);
    MovieFileOutput.maxRecordedDuration = maxDuration;
    MovieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;
    if ([CaptureSession canAddOutput:MovieFileOutput])
        [CaptureSession addOutput:MovieFileOutput];
    [self CameraSetOutputProperties];
    [CaptureSession setSessionPreset:AVCaptureSessionPreset352x288];
    CGRect layerRect = CGRectMake(0, 70, self.view.frame.size.width, 300);
    PreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [PreviewLayer setBounds:layerRect];
    [PreviewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                          CGRectGetMidY(layerRect))];
    [PreviewLayer captureDevicePointOfInterestForPoint:CGPointMake(0, 40)];
    UIView *CameraView = [[UIView alloc] init];
    CameraView.backgroundColor = [UIColor blackColor];
    [[self view] addSubview:CameraView];
    [self.view sendSubviewToBack:CameraView];
    self.view.backgroundColor = [UIColor blackColor];
    [[CameraView layer] addSublayer:PreviewLayer];
    [CaptureSession startRunning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    WeAreRecording = NO;
}

- (void) CameraSetOutputProperties {
    AVCaptureConnection *CaptureConnection = [MovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([CaptureConnection isVideoOrientationSupported]) {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
        [CaptureConnection setVideoOrientation:orientation];
    }
    CMTimeShow(CaptureConnection.videoMinFrameDuration);
    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    if (CaptureConnection.supportsVideoMinFrameDuration)
        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    if (CaptureConnection.supportsVideoMaxFrameDuration)
        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    CMTimeShow(CaptureConnection.videoMinFrameDuration);
    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
}

- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position {
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices) {
        if ([Device position] == Position) {
            return Device;
        }
    }
    return nil;
}


- (IBAction)CameraToggleButtonPressed:(id)sender {
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1) {
        NSError *error;
        AVCaptureDeviceInput *NewVideoInput;
        AVCaptureDevicePosition position = [[VideoInputDevice device] position];
        if (position == AVCaptureDevicePositionBack) {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionFront] error:&error];
        }
        else if (position == AVCaptureDevicePositionFront) {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionBack] error:&error];
        }
        if (NewVideoInput != nil) {
            [CaptureSession beginConfiguration];
            [CaptureSession removeInput:VideoInputDevice];
            if ([CaptureSession canAddInput:NewVideoInput]) {
                [CaptureSession addInput:NewVideoInput];
                VideoInputDevice = NewVideoInput;
            }
            else {
                [CaptureSession addInput:VideoInputDevice];
            }
            [self CameraSetOutputProperties];
            [CaptureSession commitConfiguration];
        }
    }
}


- (IBAction)StartStopButtonPressed:(id)sender {
    if (!WeAreRecording) {
        WeAreRecording = YES;
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath]) {
            NSError *error;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
                //Error - handle if requried
            }
        }
        [MovieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    }
    else {
        WeAreRecording = NO;
        [MovieFileOutput stopRecording];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully) {
        /*ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
         if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL]) {
         [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
         completionBlock:^(NSURL *assetURL, NSError *error) {
         if (error) {}
         }];
         }*/
        [self createSquareVideo:outputFileURL];
    }
}

- (void)dealloc {
    CaptureSession = nil;
    MovieFileOutput = nil;
    VideoInputDevice = nil;
}

- (void)createSquareVideo:(NSURL *)outputURL {
    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString* outputPath = [docFolder stringByAppendingPathComponent:@"output2.mov"];
    NSURL *exportUrl = [NSURL fileURLWithPath:outputPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    AVAsset* asset = [AVAsset assetWithURL:outputURL];
    //create an avassetrack with our asset
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //create a video composition and preset some settings
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    //here we are setting its render size to its height x height (Square)
    videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
    //create a video instruction
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30));
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    //Use this code if you want the viewing square to be in the middle of the video
    CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -((clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) /2  + 2));
    //Make sure the square is portrait
    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    //add the transformer layer instructions, then add to video composition
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    //Export
    exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = exportUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             //Call when finished
             [self exportDidFinish:exporter];
         });
     }];
}

- (void)exportDidFinish:(AVAssetExportSession*)session {
    //Play the New Cropped video
    NSURL *outputURL = session.outputURL;
    NSLog(@"send the url to plugin");
    
    if ([[self delegate] respondsToSelector:@selector(doneWithRecordingVideo:)]) {
        [[self delegate] doneWithRecordingVideo:outputURL];
    }
    
//    PreviewViewController *previewController = [[PreviewViewController alloc] init];
//    previewController.videoURL = outputURL;//outputFileURL;
//    [self presentViewController:previewController animated:YES completion:^{
//    }];
}




@end
