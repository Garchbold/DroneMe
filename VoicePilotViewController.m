//
//  VoicePilotViewController.m
//  DJISDKSwiftDemo
//
//  Created by George Archbold on 6/4/17.
//  Copyright © 2017 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VoicePilotViewController.h"
#import <DJISDK/DJISDK.h>
#import <VideoPreviewer/VideoPreviewer.h>

#define WeakRef(__obj) __weak typeof(self) __obj = self
#define WeakReturn(__obj) if(__obj ==nil)return;

@interface VoicePilotViewController ()<DJIVideoFeedListener, DJISDKManagerDelegate, DJIBaseProductDelegate, DJICameraDelegate>

@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *changeWorkModeSegmentControl;
@property (weak, nonatomic) IBOutlet UIView *fpvPreviewView;
@property (assign, nonatomic) BOOL isRecording;
@property (weak, nonatomic) IBOutlet UILabel *currentRecordTimeLabel;

- (IBAction)captureAction:(id)sender;
- (IBAction)recordAction:(id)sender;
- (IBAction)changeWorkModeAction:(id)sender;

@end

@implementation VoicePilotViewController


//Functions for first person camera display

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    DJICamera *camera = [self fetchCamera];
    if (camera && camera.delegate == self) {
        [camera setDelegate:nil];
    }
    [self resetVideoPreview];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self registerApp];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.currentRecordTimeLabel setHidden:YES];
    
    _microphoneBtn.enabled = NO;
    _speechRecognizer.delegate = self;
    _audioEngine = [[AVAudioEngine alloc] init];
    [self configSpeechRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupVideoPreviewer {
    [[VideoPreviewer instance] setView:self.fpvPreviewView];
    DJIBaseProduct *product = [DJISDKManager product];
    if ([product.model isEqual:DJIAircraftModelNameA3] ||
        [product.model isEqual:DJIAircraftModelNameN3] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600Pro]){
        [[DJISDKManager videoFeeder].secondaryVideoFeed addListener:self withQueue:nil];
        
    }else{
        [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
    }
    [[VideoPreviewer instance] start];
}

- (void)resetVideoPreview {
    [[VideoPreviewer instance] unSetView];
    DJIBaseProduct *product = [DJISDKManager product];
    if ([product.model isEqual:DJIAircraftModelNameA3] ||
        [product.model isEqual:DJIAircraftModelNameN3] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600Pro]){
        [[DJISDKManager videoFeeder].secondaryVideoFeed removeListener:self];
    }else{
        [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];
    }
}

#pragma mark Custom Methods
- (DJICamera*) fetchCamera {
    
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).camera;
    }else if ([[DJISDKManager product] isKindOfClass:[DJIHandheld class]]){
        return ((DJIHandheld *)[DJISDKManager product]).camera;
    }
    
    return nil;
}

- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)registerApp
{
    //Please enter your App key in the "DJISDKAppKey" key in info.plist file.
    [DJISDKManager registerAppWithDelegate:self];
}

- (NSString *)formattingSeconds:(NSUInteger)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSString *formattedTimeString = [formatter stringFromDate:date];
    return formattedTimeString;
}

#pragma mark DJIBaseProductDelegate Method
- (void)productConnected:(DJIBaseProduct *)product
{
    if(product){
        [product setDelegate:self];
        DJICamera *camera = [self fetchCamera];
        if (camera != nil) {
            camera.delegate = self;
        }
        [self setupVideoPreviewer];
    }
}

- (void)productDisconnected
{
    DJICamera *camera = [self fetchCamera];
    if (camera && camera.delegate == self) {
        [camera setDelegate:nil];
    }
    [self resetVideoPreview];
    
}

#pragma mark DJISDKManagerDelegate Method

- (void)appRegisteredWithError:(NSError *)error
{
    NSString* message = @"Register App Successed!";
    if (error) {
        message = @"Register App Failed! Please enter your App Key and check the network.";
    }else
    {
        NSLog(@"registerAppSuccess");
        
        [DJISDKManager startConnectionToProduct];
    }
    
    [self showAlertViewWithTitle:@"Register App" withMessage:message];
}

#pragma mark - DJICameraDelegate

-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState
{
    self.isRecording = systemState.isRecording;
    
    [self.currentRecordTimeLabel setHidden:!self.isRecording];
    [self.currentRecordTimeLabel setText:[self formattingSeconds:systemState.currentVideoRecordingTimeInSeconds]];
    
    if (self.isRecording) {
        [self.recordBtn setTitle:@"Stop Record" forState:UIControlStateNormal];
    }else
    {
        [self.recordBtn setTitle:@"Start Record" forState:UIControlStateNormal];
    }
    
    //Update UISegmented Control's state
    if (systemState.mode == DJICameraModeShootPhoto) {
        [self.changeWorkModeSegmentControl setSelectedSegmentIndex:0];
    }else if (systemState.mode == DJICameraModeRecordVideo){
        [self.changeWorkModeSegmentControl setSelectedSegmentIndex:1];
    }
    
}

#pragma mark - DJIVideoFeedListener
-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData {
    [[VideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
}

#pragma mark - IBAction Methods

- (IBAction)captureAction:(id)sender {
    
    __weak DJICamera* camera = [self fetchCamera];
    if (camera) {
        WeakRef(target);
        [camera setShootPhotoMode:DJICameraShootPhotoModeSingle withCompletion:^(NSError * _Nullable error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [camera startShootPhotoWithCompletion:^(NSError * _Nullable error) {
                    WeakReturn(target);
                    if (error) {
                        [target showAlertViewWithTitle:@"Take Photo Error" withMessage:error.description];
                    }
                }];
            });
        }];
    }
    
}

- (IBAction)recordAction:(id)sender {
    
    __weak DJICamera* camera = [self fetchCamera];
    if (camera) {
        WeakRef(target);
        if (self.isRecording) {
            [camera stopRecordVideoWithCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [target showAlertViewWithTitle:@"Stop Record Video Error" withMessage:error.description];
                }
            }];
        }else
        {
            [camera startRecordVideoWithCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [target showAlertViewWithTitle:@"Start Record Video Error" withMessage:error.description];
                }
            }];
        }
    }
}

- (IBAction)changeWorkModeAction:(id)sender {
    
    UISegmentedControl *segmentControl = (UISegmentedControl *)sender;
    __weak DJICamera* camera = [self fetchCamera];
    
    if (camera) {
        WeakRef(target);
        if (segmentControl.selectedSegmentIndex == 0) { //Take photo
            
            [camera setMode:DJICameraModeShootPhoto withCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [target showAlertViewWithTitle:@"Set DJICameraModeShootPhoto Failed" withMessage:error.description];
                }
            }];
            
        }else if (segmentControl.selectedSegmentIndex == 1){ //Record video
            
            [camera setMode:DJICameraModeRecordVideo withCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [target showAlertViewWithTitle:@"Set DJICameraModeRecordVideo Failed" withMessage:error.description];
                }
            }];
            
        }
    }
    
}

//Functions for speech recognition

- (void)configSpeechRecognizer {
    _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus authStatus) {
        BOOL isButtonEnabled = NO;
        switch (authStatus) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                //User gave access to speech recognition
                NSLog(@"Authorized");
                isButtonEnabled = YES;
                break;
                
            case SFSpeechRecognizerAuthorizationStatusDenied:
                //User denied access to speech recognition
                NSLog(@"SFSpeechRecognizerAuthorizationStatusDenied");
                break;
                
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                //Speech recognition restricted on this device
                NSLog(@"SFSpeechRecognizerAuthorizationStatusRestricted");
                break;
                
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                //Speech recognition not yet authorized
                NSLog(@"SFSpeechRecognizerAuthorizationStatusNotDetermined");
                break;
                
            default:
                NSLog(@"Default");
                break;
        }
        
        // http://stackoverflow.com/questions/31951704/this-application-is-modifying-the-autolayout-engine-from-a-background-thread-wh
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _microphoneBtn.enabled = isButtonEnabled;
        }];
    }];
}


- (IBAction)microphoneTapped:(id)sender {
    if ([_audioEngine isRunning]) {
        NSLog(@"AUDIO ENGINE IS RUNNING");
        [_audioEngine stop];
        [_recognitionRequest endAudio];
        _microphoneBtn.enabled = NO;
        [_microphoneBtn setTitle:@"Start Recording" forState:UIControlStateNormal];
    } else {
        NSLog(@"AUDIO ENGINE IS WORKING");
        [self startRecording];
        [_microphoneBtn setTitle:@"Stop Recording" forState:UIControlStateNormal];
    }
}


-(void)startRecording { // http://stackoverflow.com/questions/37821826/continuous-speech-recogn-with-sfspeechrecognizer-ios10-beta
    if (_recognitionTask != nil) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    NSError * outError;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    @try {
        [audioSession setCategory:AVAudioSessionCategoryRecord error:&outError];
        [audioSession setMode:AVAudioSessionModeMeasurement error:&outError];
        [audioSession setActive:true withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation  error:&outError];
    } @catch (NSException * e) {
        NSLog(@"audioSession properties weren't set because of an error. %@", e);
    }
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    _inputNode = [_audioEngine inputNode];
    if (_inputNode == nil) {
        NSLog(@"Audio engine has no input node");
    }
    if (_recognitionRequest == nil) {
        NSLog(@"Unable to created a SFSpeechAudioBufferRecognitionRequest object");
    }
    _recognitionRequest.shouldReportPartialResults = YES;
    _recognitionTask = [_speechRecognizer recognitionTaskWithRequest:_recognitionRequest
                                                       resultHandler:^(SFSpeechRecognitionResult *result, NSError *error) {
                                                           BOOL isFinal = NO;
                                                           if (result != nil) {
                                                               _textView.text = result.bestTranscription.formattedString;
                                                               isFinal = result.isFinal;
                                                           }
                                                           if (error != nil || isFinal) {
                                                               [_audioEngine stop];
                                                               [_inputNode removeTapOnBus:0];
                                                               _recognitionRequest = nil;
                                                               _recognitionTask = nil;
                                                               _microphoneBtn.enabled = YES;
                                                           }
                                                       }];
    
    AVAudioFormat *recordingFormat = [_inputNode outputFormatForBus:0];
    [_inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        [_recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    [_audioEngine prepare];
    
    @try {
        [_audioEngine startAndReturnError:&outError];
    } @catch (NSException *e) {
        NSLog(@"audioEngine couldn't start because of an error. %@", e);
    }
    
    _textView.text = @"Say something, I'm listening!";
}

- (void)speechRecognizer:(SFSpeechRecognizer*)speechRecognizer availabilityDidChange:(BOOL)available {
    _microphoneBtn.enabled = available;
    NSLog(@"AVAILABLE: %@", (available?@"YES":@"NO"));
}

@end
