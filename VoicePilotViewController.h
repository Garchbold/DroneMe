//
//  VoicePilotViewController.h
//  DJISDKSwiftDemo
//
//  Created by George Archbold on 6/4/17.
//  Copyright © 2017 DJI. All rights reserved.
//

#ifndef VoicePilotViewController_h
#define VoicePilotViewController_h

#import <UIKit/UIKit.h>
#import <Speech/Speech.h>
#import <Speech/SFSpeechRecognizer.h>

@interface VoicePilotViewController : UIViewController <SFSpeechRecognizerDelegate>
@property (nonatomic) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic) AVAudioEngine *audioEngine;
@property (nonatomic) AVAudioInputNode *inputNode;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *microphoneBtn;
- (IBAction)microphoneTapped:(id)sender;



@end

#endif /* VoicePilotViewController_h */
