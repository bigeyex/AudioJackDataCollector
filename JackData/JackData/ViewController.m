//
//  ViewController.m
//  JackData
//
//  Created by Wang Yu on 2/6/15.
//  Copyright (c) 2015 Wang Yu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    COMPLEX_SPLIT _A;
    FFTSetup      _FFTSetup;
    BOOL          _isFFTSetup;
    vDSP_Length   _log2n;
    NSMutableArray *sampleList;
    BOOL          isTakingSample;
}
@end

@implementation ViewController
@synthesize audioPlotFreq;
@synthesize microphone;

#pragma mark - Customize the Audio Plot
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup frequency domain audio plot
    self.audioPlotFreq.backgroundColor = [UIColor colorWithRed: 0.984 green: 0.471 blue: 0.525 alpha: 1];
    self.audioPlotFreq.color           = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.audioPlotFreq.shouldFill      = YES;
    self.audioPlotFreq.plotType        = EZPlotTypeBuffer;
    
    /*
     Start the microphone
     */
    self.microphone = [EZMicrophone microphoneWithDelegate:self
                                         startsImmediately:YES];
    
    isTakingSample = NO;
    sampleList = [NSMutableArray array];
    
}

- (IBAction)takeASamplePressed:(id)sender {
    if(!isTakingSample){
        isTakingSample = YES;
        [self.takeASampleButton setTitle:@"Stop" forState:UIControlStateNormal];
        self.takeASampleButton.tintColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    }
    else{
        isTakingSample = NO;
        [sampleList removeAllObjects];
        [self.takeASampleButton setTitle:@"Sample" forState:UIControlStateNormal];
        self.takeASampleButton.tintColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        
        // calculate sample data
        
    }
}

#pragma mark - FFT
/**
 Adapted from http://batmobile.blogs.ilrt.org/fourier-transforms-on-an-iphone/
 */
-(void)createFFTWithBufferSize:(float)bufferSize withAudioData:(float*)data {
    
    // Setup the length
    _log2n = log2f(bufferSize);
    
    // Calculate the weights array. This is a one-off operation.
    _FFTSetup = vDSP_create_fftsetup(_log2n, FFT_RADIX2);
    
    // For an FFT, numSamples must be a power of 2, i.e. is always even
    int nOver2 = bufferSize/2;
    
    // Populate *window with the values for a hamming window function
    float *window = (float *)malloc(sizeof(float)*bufferSize);
    vDSP_hamm_window(window, bufferSize, 0);
    // Window the samples
    vDSP_vmul(data, 1, window, 1, data, 1, bufferSize);
    free(window);
    
    // Define complex buffer
    _A.realp = (float *) malloc(nOver2*sizeof(float));
    _A.imagp = (float *) malloc(nOver2*sizeof(float));
    
}

-(void)updateFFTWithBufferSize:(float)bufferSize withAudioData:(float*)data {
    
    // For an FFT, numSamples must be a power of 2, i.e. is always even
    int nOver2 = bufferSize/2;
    
    // Pack samples:
    // C(re) -> A[n], C(im) -> A[n+1]
    vDSP_ctoz((COMPLEX*)data, 2, &_A, 1, nOver2);
    
    // Perform a forward FFT using fftSetup and A
    // Results are returned in A
    vDSP_fft_zrip(_FFTSetup, &_A, 1, _log2n, FFT_FORWARD);
    
    // Convert COMPLEX_SPLIT A result to magnitudes
    float amp[nOver2];
    float maxMag = 0;
    int highestBin = 0;
    
    for(int i=0; i<nOver2; i++) {
        // Calculate the magnitude
        float mag = _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i];
        if(mag > maxMag){
            highestBin = i;
            maxMag = mag;
        }
    }
    float frequency = highestBin / bufferSize * 44100;
    [self.currentReading setText:[NSString stringWithFormat:@"%.2f Hz", frequency]];
    
    // save data for statistics
    if(isTakingSample){
        [sampleList addObject:[NSNumber numberWithFloat:frequency]];
        [self updateSampleStatus];
    }
    
    
    for(int i=0; i<nOver2; i++) {
        // Calculate the magnitude
        float mag = _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i];
        // Bind the value to be less than 1.0 to fit in the graph
        amp[i] = [EZAudio MAP:mag leftMin:0.0 leftMax:maxMag rightMin:0.0 rightMax:1.0];
    }
    
    // Update the frequency domain plot
    [self.audioPlotFreq updateBuffer:amp
                      withBufferSize:nOver2];
    
}

- (void)updateSampleStatus{
    int numberOfSample = sampleList.count;
    // calculate average
    float average = 0;
    float sum = 0;
    float errorMargin = 0;
    for (id valueObject in sampleList){
        float value = [valueObject floatValue];
        sum += value;
    }
    average = sum / (float)numberOfSample;
    
    if(numberOfSample>1){
        float sdsum=0;
        for (id valueObject in sampleList){
            float value = [valueObject floatValue];
            sdsum += (average-value)*(average-value);
        }
        float sd = sqrtf((sdsum/(numberOfSample-1)));
        errorMargin = sd/sqrtf((float)numberOfSample)*1.96;
    }
    
    
    [self.sampleStatus setText:[NSString stringWithFormat:@"n=%d, avg=%.2f±%.2f", numberOfSample, average, errorMargin]];
    
}

#pragma mark - EZMicrophoneDelegate
-(void)    microphone:(EZMicrophone *)microphone
     hasAudioReceived:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Setup the FFT if it's not already setup
        if( !_isFFTSetup ){
            [self createFFTWithBufferSize:bufferSize withAudioData:buffer[0]];
            _isFFTSetup = YES;
        }
        
        // Get the FFT data
        [self updateFFTWithBufferSize:bufferSize withAudioData:buffer[0]];
        
    });
}

@end
