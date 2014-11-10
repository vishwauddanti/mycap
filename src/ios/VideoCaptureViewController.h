//
//  VideoCaptureViewController.h
//  CheckVideoRecording
//
//  Created by Vishwanath on 10/11/14.
//  Copyright (c) 2014 Vishwanath. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#define CAPTURE_FRAMES_PER_SECOND		20


@protocol VideoCaptureDelegate <NSObject>
@optional
- (void)doneWithRecordingVideo:(NSURL *)videoCaputureURL;
@end

@interface VideoCaptureViewController : UIViewController<AVCaptureFileOutputRecordingDelegate> {
    BOOL WeAreRecording;
    
    AVCaptureSession *CaptureSession;
    AVCaptureMovieFileOutput *MovieFileOutput;
    AVCaptureDeviceInput *VideoInputDevice;
    AVAssetExportSession *exporter;
}

@property (strong) AVCaptureVideoPreviewLayer *PreviewLayer;
@property (nonatomic, weak) id <VideoCaptureDelegate> delegate;

- (void) CameraSetOutputProperties;
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position;
- (IBAction)StartStopButtonPressed:(id)sender;
- (IBAction)CameraToggleButtonPressed:(id)sender;
- (void)captureVideo;


@end
