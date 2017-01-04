//
//  AudioViewController.h
//  sample-content
//
//  Created by Brenda Saavedra on 1/3/17.
//  Copyright © 2017 Igor Khomenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Quickblox/Quickblox.h>

@protocol AudioViewControllerDelegate <NSObject>
- (void)addAudio:(QBCBlob *)blob;
@end

@interface AudioViewController : UIViewController<AVAudioRecorderDelegate, AVAudioPlayerDelegate>
{
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
}
@property (nonatomic, weak) id <AudioViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIButton *btnRecord;
@property (nonatomic, weak) IBOutlet UIButton *btnPlay;
@property (nonatomic, weak) IBOutlet UIButton *btnSave;
- (IBAction)recordTapped:(id)sender;
- (IBAction)playTapped:(id)sender;
- (IBAction)saveTapped:(id)sender;

@end
