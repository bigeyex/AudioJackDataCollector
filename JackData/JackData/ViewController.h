//
//  ViewController.h
//  JackData
//
//  Created by Wang Yu on 2/6/15.
//  Copyright (c) 2015 Wang Yu. All rights reserved.
//


#import <UIKit/UIKit.h>

/**
 EZAudio
 */
#import "EZAudio.h"

/**
 Accelerate
 */
#import <Accelerate/Accelerate.h>

/**
 The FFTViewController demonstrates how to use the Accelerate framework to calculate the real-time FFT of audio data provided by an EZAudioMicrophone.
 */
@interface ViewController : UIViewController <EZMicrophoneDelegate>

#pragma mark - Components
/**
 EZAudioPlot for frequency plot
 */
@property (nonatomic,weak) IBOutlet EZAudioPlot *audioPlotFreq;
@property (weak, nonatomic) IBOutlet UILabel *currentReading;
@property (weak, nonatomic) IBOutlet UIButton *takeASampleButton;
@property (weak, nonatomic) IBOutlet UILabel *sampleStatus;

/**
 EZAudioPlot for time plot
 */

/**
 Microphone
 */
@property (nonatomic,strong) EZMicrophone *microphone;

@end
