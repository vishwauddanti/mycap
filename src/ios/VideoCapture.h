//
//  VideoCapture.h
//  CheckVideoRecording
//
//  Created by Vishwanath on 10/11/14.
//  Copyright (c) 2014 Vishwanath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface VideoCapture : CDVPlugin {
}

- (void)captureVideo:(CDVInvokedUrlCommand*)command;

@end
