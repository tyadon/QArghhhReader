//
//  ViewController.h
//  QArghhhReader
//
//  Created by Trey Yadon on 4/16/14.
//  Copyright (c) 2014 Richard Yadon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>
@property (weak, nonatomic) IBOutlet UIView *viewPreview;
@property (weak, nonatomic) IBOutlet UILabel *lblCurrentStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnItemStart;
- (IBAction)startStopRecording:(id)sender;

@end
