//
//  DHAudioRecorder.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHAudioAttributes.h"
#import <AudioToolbox/AudioToolbox.h>

#define kDHAudioRecorderErrorKey @"localizedDescription"

typedef NS_ENUM(NSInteger, DHRecorderError) {
    DHRecorderErrorFailToSetUpAudioSession,
    DHRecorderErrorFailToFillInAudioFormat,
    DHRecorderErrorFailToCreateRecorder,
    DHRecorderErrorFailToRecordData,
    DHRecorderErrorFailToEnableMetering,
    DHRecorderErrorFailToGetMeteringData,
};

@class DHAudioRecorder;

@protocol DHAudioRecorderDelegate <NSObject>
@required
/**
 * @discussion Every time the audio buffer is filled, this delegate method will be called to return the recorded audio data；The interval that the method will be called is determined by the `packetDuration` property;
 *
 * @param recorder the recorder.
 * @param data the recorded data, the format and type of the data depends on the type of recorder you created.
 * @param numberOfPackets number of packets recorded in this buffer.
 */
- (void) audioRecorder:(DHAudioRecorder *)recorder
         didRecordData:(NSData *)data
       numberOfPackets:(int)numberOfPackets;

@optional
/**
 * Implement this method if you want to receive errors while recording audios;
 * Get the detailed error information by accessing the `userInfo` with `kDHAudioRecorderErrorKey`
 * You can find the error code in `DHRecorderError`
 *
 * @param recorder the recorder;
 * @param error the detailed error info.
 */
- (void) audioRecorder:(DHAudioRecorder *)recorder didFailToRecordWithError:(NSError *)error;

/**
 * Implement this method if you want to get notified when recording is really finished;
 * 
 * @discussion By calling `stopRecording` method, the recorder will be notified to stop recording, but the recording is not finished immediately. This method gives you a chance to know when the recording process is actually finished.
 *
 * @param recorder the recorder;
 */
- (void) audioRecorderDidFinishRecording:(DHAudioRecorder *)recorder;

/**
 * Implement this method if you want to get notified when recording is paused;
 *
 * @param recorder the recorder;
 * @param event the event that triggered the pause, see `DHAudioPauseEvent`
 */
- (void) audioRecorder:(DHAudioRecorder *)recorder
    didPauseDueToEvent:(DHAudioPauseEvent)event;

/**
 * Implement this method if you want to get notified when recording is resumed;
 *
 * @param recorder the recorder;
 * @param event the event that triggered the pause, see `DHAudioPauseEvent`
 */
- (void) audioRecorder:(DHAudioRecorder *)recorder
  willResumeAfterEvent:(DHAudioPauseEvent) event;

/**
 * Implement this method if you want to get notified when session router is changed, e.g. plugin your ;
 *
 * @param recorder the recorder;
 * @param userInfo the session router user information.
 */
- (void) audioRecorder:(DHAudioRecorder *)recorder
didChangeAudioSessionRoute:(NSDictionary *)userInfo;

@end

/**
 DHAudioRecorder is a recorder class that can record and return audio data by using microphones on iOS devices;
 DHAudioRecorder is a base class that records and return the linear PCM data to the delegate;
 If you want recorders that can return other formats of audio data, please check out the following recorders:
    * DHAACAudioRecorder
    * DHMP3AudioRecorder
    * DHOpusAudioRecorder
 */
@interface DHAudioRecorder : NSObject

/**
 * The time interval used to discribe the size of the recording buffer and the duration that each time the recorder returned;
 * The `delegate的audioRecorder:didRecordData:numberOfPackets` method will be called every time after packetDuration is passed;
 * Default value is 0.5;
 *
 * @discussion The packet duration will differ due to different audio format;
    * For formats like AAC, MP3, the value should not be to small, otherwise conversion will fail, it should be larger than 0.3;
    * For Opus, the value should be 0.005, 0.01, 0.02, 0.04 etc.
 */
@property (nonatomic) NSTimeInterval packetDuration;

/**
 * The input format for recorder, this format will describe the Linear PCM data recorded by iOS;
 * Default values are:
        sampleRate = 16000
        numberOfChannels = 1
        bitsPerChannel = 16
        flags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
 */
@property (nonatomic, readonly) AudioStreamBasicDescription audioFormat;

/**
 * The delegate which will handle the events for recorder;
 */
@property (nonatomic, weak) id<DHAudioRecorderDelegate> delegate;

/**
 * The queue on which the delegate is running.
 * Default value is dispatch_get_main_queue()
 */
@property (nonatomic, weak) dispatch_queue_t delegateQueue;

/**
 * The number of packets recorded. Used to tell whether the recording process is finished by subclasses;
 */
@property (nonatomic) NSInteger numberOfPacketsRecorded;

/**
 * The current duration of the recorded audio;
 */
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 * Convenience Initializer;
 * @param audioFormat recorded audio format;
 * @param packetDuration time interval for returning data;
 * @param delegate delegate to deal with events;
 */
- (instancetype) initWithFormat:(AudioStreamBasicDescription)audioFormat
                 packetDuration:(NSTimeInterval) packetDuration
                       delegate:(id<DHAudioRecorderDelegate>)delegate;

/**
 * Convenience Initializer;
 * @param audioFormat recorded audio format;
 * @param packetDuration time interval for returning data;
 * @param delegate delegate to deal with events;
 * @param delegateQueue the queue on which the delegate is running
 */
- (instancetype) initWithFormat:(AudioStreamBasicDescription)audioFormat
                 packetDuration:(NSTimeInterval) packetDuration
                       delegate:(id<DHAudioRecorderDelegate>)delegate
                  delegateQueue:(dispatch_queue_t)delegateQueue;

/**
 * Start recording;
 * @discussion start recording multiple times for a recorder will stop the previous recording session;
 */
- (void) startRecording;

/**
 * Pause recording;
 */
- (void) pauseRecording;

/**
 * Resume recording from pause state;
 */
- (void) resumeRecording;

/**
 * Notify the recorder to stop recording, but the recording session is not stopped immediately;
 * If you want to get notified when recording is done, you can implement `audioRecorderDidFinishRecording` method in the `delegate`
 */
- (void) stopRecording;

/**
 * Current audio meter level; Between 0-1;
 */
- (double) currentMeter;

/**
 * Default format for recorder;
    sampleRate = 16000
    numberOfChannels = 1
    bitsPerChannel = 16
    flags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
 */
+ (AudioStreamBasicDescription) defaultFormat;

#pragma mark - For SubClassing
/**
 * For Subclassing. Subclass can override this method and process the pcm data recorded by iOS, and then return the data to the delegate by calling `audioRecorder:didRecordData:numberOfPackets`
 * @param pcmData the PCM data recordedd by audio queue;
 * @param numberOfPackets number of Packets in the data;
 */
- (void) processPCMData:(NSData *)pcmData
        numberOfPackets:(int)numberOfPackets;

/**
 * For Subclassing. Subclass can override this method to clean up converter resource;
 */
- (void) cleanUpResource;
@end
