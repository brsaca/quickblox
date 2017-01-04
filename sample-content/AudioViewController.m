//
//  AudioViewController.m
//  sample-content
//
//  Created by Brenda Saavedra on 1/3/17.
//  Copyright © 2017 Igor Khomenko. All rights reserved.
//

#import "AudioViewController.h"
#import <SVProgressHUD.h>

@interface AudioViewController (){
    NSArray *path;
}

@end

@implementation AudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.btnPlay setEnabled:NO];
    [self.btnSave setEnabled:NO];
    
    path = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"recording.m4a",nil];
    NSURL *url = [NSURL fileURLWithPathComponents:path];
    
    AVAudioSession *session = [[AVAudioSession alloc]init];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    NSMutableDictionary *setting = [[NSMutableDictionary alloc]init];
    [setting setValue:[NSNumber numberWithInteger:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [setting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [setting setValue:[NSNumber numberWithInteger:2] forKey:AVNumberOfChannelsKey];
    
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:nil];
    recorder.meteringEnabled = YES;
    recorder.delegate = self;
    [recorder prepareToRecord];
    [recorder record];
}

#pragma mark - IBAction

- (IBAction)recordTapped:(id)sender {
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    if (!recorder.recording) {
        [session setActive:YES error:nil];
        
        // Start recording
        [recorder record];
        [self.btnRecord setTitle:@"Stop" forState:UIControlStateNormal];
        [self.btnPlay setEnabled:NO];
    } else {
        
        // Stop recording
        [recorder stop];
        
        [session setActive:NO error:nil];
        
        [self.btnRecord setTitle:@"Record" forState:UIControlStateNormal];
        [self.btnPlay setEnabled:YES];
        [self.btnSave setEnabled:YES];
    }
    
}

- (IBAction)playTapped:(id)sender {
    if (!recorder.recording){
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
        [player setDelegate:self];
        [player play];
    }
}

- (IBAction)saveTapped:(id)sender {
    NSData *audioData = [NSData dataWithContentsOfURL:recorder.url];
    [SVProgressHUD showWithStatus:@"Uploading audio..."];
    [QBRequest TUploadFile:audioData fileName:@"audio" contentType:@"audio/m4a" isPublic:YES
              successBlock:^(QBResponse *response, QBCBlob *blob) {
                  [SVProgressHUD dismiss];
                  if([self.delegate respondsToSelector:@selector(addAudio:)]){
                      [self.navigationController popViewControllerAnimated:YES];
                      [self.delegate addAudio:blob];
                  }
              } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
                   [SVProgressHUD showProgress:status.percentOfCompletion status:@"Uploading audio"];
              } errorBlock:^(QBResponse *response) {
                  [SVProgressHUD dismiss];
                  NSLog(@"error: %@", response.error);

                  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error while uploading new file"
                                                                  message:[response.error description]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles: nil];
                  [alert show];
              }];
    
}

#pragma mark - AVAudioRecorderDelegate

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [self.btnRecord setTitle:@"Record" forState:UIControlStateNormal];
    [self.btnPlay setEnabled:YES];
    [self.btnSave setEnabled:YES];
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    
}

@end
