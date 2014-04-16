//
//  ViewController.m
//  QArghhhReader
//
//  Created by Trey Yadon on 4/16/14.
//  Copyright (c) 2014 Richard Yadon. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

// Session
@property (nonatomic) BOOL isActive;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;

// Storyboard
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer;

// Utilities
- (BOOL)startReading;
- (void)stopReading;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.isActive = NO;
    
    self.captureSession = nil;
}

- (BOOL)startReading {
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [self setCaptureDevice:captureDevice];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"Error: %@", [error localizedDescription]);
        return NO;
    }
    
    self.captureSession = [[AVCaptureSession alloc] init];
    
    if ([self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    } else {
        NSLog(@"Capture input is not compatible with session");
    }
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    if ([self.captureSession canAddOutput:captureMetadataOutput]) {
        [self.captureSession addOutput:captureMetadataOutput];
    } else {
        NSLog(@"Capture output is not compatible with session");
    }
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("session queue", NULL);
    
    [self setSessionQueue:dispatchQueue];
    
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.previewLayer setFrame:self.viewPreview.layer.bounds];
    [self.viewPreview.layer addSublayer:self.previewLayer];
    
    [self.captureSession startRunning];
    
    
    return YES;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if ((metadataObjects != nil) && ([metadataObjects count] > 0)) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self.lblCurrentStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(setButtonTitle:) withObject:@"Start" waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            self.isActive = NO;
        }
    }
}

- (void)stopReading {
    [self.captureSession stopRunning];
    self.captureSession = nil;
    [self.previewLayer removeFromSuperlayer];
}

#pragma mark UI

- (void)setButtonTitle:(NSString *)title {
    [self.btnItemStart setTitle:@"Start" forState:UIControlStateNormal];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *device = [self captureDevice];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    });
}

#pragma mark Actions

- (IBAction)startStopRecording:(id)sender {
    
    if (!self.isActive) {
        if ([self startReading]) {
            [self.btnItemStart setTitle:@"Stop" forState:UIControlStateNormal];
            [self.lblCurrentStatus setText:@"Scanning Now"];
        }
    } else {
        [self stopReading];
        [self.btnItemStart setTitle:@"Start" forState:UIControlStateNormal];
        [self.lblCurrentStatus setText:@"QR is Inactive"];
    }
    
    self.isActive = !self.isActive;
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.isActive) {
        CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewLayer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
        [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
    }
}



@end
