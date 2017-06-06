//
//  DHAudioRecorder.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAudioRecorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static const int kNumberBuffers = 3;
static const int kNumberOfBitsInAByte = 8;

static const int kDefaultNumberOfChannels = 1;
static const int kDefaultNumberOfBitsPerChannel = 16;
static const NSTimeInterval kDefaultRecordDuration = 0.5;

typedef NS_ENUM(NSInteger, ALTYAudioRecorderStatus) {
    ALTYAudioRecorderStatusNotStarted,
    ALTYAudioRecorderStatusRecording,
    ALTYAudioRecorderStatusPaused,
    ALTYAudioRecorderStatusStopped,
};

#pragma mark - Forward Declaration
typedef struct {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef               mQueue;
    AudioQueueBufferRef         mBuffers[kNumberBuffers];
    AudioFileID                 mAudioFile;
    UInt32                      bufferByteSize;
    SInt64                      mCurrentPacket;
    bool                        mIsRunning;
}AQRecorderState;

void HandleInputBuffer(
                       void                        *aqData,
                       AudioQueueRef               inAQ,
                       AudioQueueBufferRef         inBuffer,
                       const AudioTimeStamp        *inStartTime,
                       UInt32                      inNumPackets,
                       const AudioStreamPacketDescription *inPacketDesc
                       );

@interface DHAudioRecorder () {
    AQRecorderState iAqData;
}

- (AQRecorderState) aqData;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) ALTYAudioRecorderStatus status;
@end

@implementation DHAudioRecorder

#pragma mark - Initialization
- (instancetype) init
{
    AudioStreamBasicDescription audioFormat = [DHAudioRecorder defaultFormat];
    return [self initWithFormat:audioFormat
                 packetDuration:kDefaultRecordDuration
                       delegate:nil];
}

- (instancetype) initWithFormat:(AudioStreamBasicDescription)audioFormat
                 packetDuration:(NSTimeInterval)packetDuration
                       delegate:(id<DHAudioRecorderDelegate>)delegate
{
    return [self initWithFormat:audioFormat
                 packetDuration:packetDuration
                       delegate:delegate
                  delegateQueue:dispatch_get_main_queue()];
}

- (instancetype) initWithFormat:(AudioStreamBasicDescription)audioFormat
                 packetDuration:(NSTimeInterval)packetDuration
                       delegate:(id<DHAudioRecorderDelegate>)delegate
                  delegateQueue:(dispatch_queue_t)delegateQueue
{
    self = [super init];
    if (self) {
        _audioFormat = audioFormat;
        _packetDuration = packetDuration;
        _delegate = delegate;
        _delegateQueue = delegateQueue;
        iAqData.mDataFormat = audioFormat;
        _status = ALTYAudioRecorderStatusNotStarted;
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Recorder Actions
- (void) startRecording
{
    if (self.status != ALTYAudioRecorderStatusNotStarted) {
        return ;
    }
    [self _setupAudioSession];
    [self _createAudioQueue];
    [self _prepareAudioQueueBuffers];
    [self _addInterruptionObservers];
    iAqData.mCurrentPacket = 0;
    iAqData.mIsRunning = true;
    AudioQueueStart(iAqData.mQueue, NULL);
    self.status = ALTYAudioRecorderStatusRecording;
    
    UInt32 enableMetering = YES;
    OSStatus status = AudioQueueSetProperty(iAqData.mQueue, kAudioQueueProperty_EnableLevelMetering, &enableMetering,sizeof(enableMetering));
    if (status) {
        [self reportErrorWithType:DHRecorderErrorFailToEnableMetering message:@"Fail To Enable Metering"];
    }
}

- (void) pauseRecording
{
    if (self.status != ALTYAudioRecorderStatusRecording) {
        return;
    }
    [self pauseAudioQueue];
    [self removeObserver];
}

- (void) pauseAudioQueue
{
    AudioQueuePause(iAqData.mQueue);
    self.status = ALTYAudioRecorderStatusPaused;
}

- (void) resumeRecording
{
    if (self.status != ALTYAudioRecorderStatusPaused) {
        return;
    }
    [self _addInterruptionObservers];
    [self resumeAudioQueue];
}

- (void) resumeAudioQueue
{
    AudioQueueStart(iAqData.mQueue, NULL);
    self.status = ALTYAudioRecorderStatusRecording;
}

- (void) stopRecording
{
    if (self.status == ALTYAudioRecorderStatusNotStarted) {
        return;
    }
    [self updateDuration];
    AudioQueueStop(iAqData.mQueue, true);
    iAqData.mIsRunning = false;
    AudioQueueDispose(iAqData.mQueue, true);
    [self cleanUpResource];
    [self removeObserver];
    self.status = ALTYAudioRecorderStatusStopped;
}

- (void) _addInterruptionObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void) removeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSTimeInterval) duration
{
    [self updateDuration];
    return _duration;
}

- (void) updateDuration
{
    if (iAqData.mIsRunning) {
        AudioQueueTimelineRef timeLine;
        OSStatus status = AudioQueueCreateTimeline(iAqData.mQueue, &timeLine);
        AudioTimeStamp timeStamp;
        status = AudioQueueGetCurrentTime(iAqData.mQueue, timeLine, &timeStamp, NULL);
        if (status == noErr) {
            _duration = timeStamp.mSampleTime / self.audioFormat.mSampleRate;
        }
    }
}

- (double) currentMeter
{
    AudioQueueLevelMeterState state[1];
    UInt32  statesize = sizeof(state);
    OSStatus status;
    status = AudioQueueGetProperty(iAqData.mQueue, kAudioQueueProperty_CurrentLevelMeter, &state, &statesize);
    if (status) {
        [self reportErrorWithType:DHRecorderErrorFailToGetMeteringData message:@"Error While Retrieving Metering Data"];
        return 0.0f;
    }
    return state[0].mAveragePower;
}

#pragma mark - Set Up Recorder
- (void) _setupAudioSession
{
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [self reportErrorWithType:DHRecorderErrorFailToSetUpAudioSession message:@"Error While Setting up Audio Session"];
}

- (void) _createAudioQueue
{
    AudioQueueNewInput(&iAqData.mDataFormat, HandleInputBuffer, (__bridge void * _Nullable)(self), NULL, kCFRunLoopCommonModes, 0, &iAqData.mQueue);
    UInt32 dataFormatSize = sizeof(iAqData.mDataFormat);
    
    OSStatus status = AudioQueueGetProperty(iAqData.mQueue, kAudioQueueProperty_StreamDescription, &iAqData.mDataFormat, &dataFormatSize);
    if (status != noErr) {
        [self reportErrorWithType:DHRecorderErrorFailToFillInAudioFormat message:@"Error while filling data format"];
    }
    
}

- (void) _prepareAudioQueueBuffers
{
    iAqData.bufferByteSize = [self _derivedBufferSize];
    for (int i = 0; i < kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(iAqData.mQueue, iAqData.bufferByteSize, &iAqData.mBuffers[i]);
        AudioQueueEnqueueBuffer(iAqData.mQueue, iAqData.mBuffers[i], 0, NULL);
    }
}

//Calculate the buffer size for recording
- (UInt32) _derivedBufferSize
{
    UInt32 maxBufferSize = 0x50000;
    UInt32 maxPacketSize = iAqData.mDataFormat.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (
                               iAqData.mQueue,
                               kAudioQueueProperty_MaximumOutputPacketSize,
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    Float64 numBytesForTime = iAqData.mDataFormat.mSampleRate * maxPacketSize * self.packetDuration;
    return numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize;
}

- (void) processPCMData:(NSData *)pcmData
        numberOfPackets:(int)numberOfPackets
{
    if ([pcmData length] == 0) {
        return;
    }
    self.numberOfPacketsRecorded++;
    dispatch_async(self.delegateQueue, ^{
        [self.delegate audioRecorder:self
                       didRecordData:pcmData
                     numberOfPackets:numberOfPackets];
    });
}

#pragma mark - Error Handling
- (void) reportErrorWithType:(DHRecorderError)errorType
                     message:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:errorType userInfo:@{kDHAudioRecorderErrorKey : message}];
    if (error) {
        if ([self.delegate respondsToSelector:@selector(audioRecorder:didFailToRecordWithError:)]) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate audioRecorder:self didFailToRecordWithError:error];
            });
        }
    }
}

#pragma mark - Getters & Setters
- (AQRecorderState) aqData
{
    return iAqData;
}

- (NSTimeInterval) packetDuration
{
    if (_packetDuration == 0) {
        _packetDuration = kDefaultRecordDuration;
    }
    return _packetDuration;
}

- (dispatch_queue_t) delegateQueue
{
    if (_delegateQueue == nil) {
        _delegateQueue = dispatch_get_main_queue();
    }
    return _delegateQueue;
}

+ (AudioStreamBasicDescription) defaultFormat
{
    AudioStreamBasicDescription format;
    format.mFormatID = kAudioFormatLinearPCM;
    format.mSampleRate = DHAudioSampleRate16000;
    format.mChannelsPerFrame = kDefaultNumberOfChannels;
    format.mBitsPerChannel = kDefaultNumberOfBitsPerChannel;
    format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    format.mBytesPerPacket = format.mBytesPerFrame = format.mBitsPerChannel / kNumberOfBitsInAByte * format.mChannelsPerFrame;
    format.mFramesPerPacket = 1;
    return format;
}

- (void) cleanUpResource
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderDidFinishRecording:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate audioRecorderDidFinishRecording:self];
        });
    }
}

#pragma mark - Handle Interruption
- (void) audioInterrupt:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *interruptionType = userInfo[AVAudioSessionInterruptionTypeKey];
    
    if ([interruptionType intValue] == AVAudioSessionInterruptionTypeBegan) {
        [self pauseAudioQueue];
        if ([self.delegate respondsToSelector:@selector(audioRecorder:didPauseDueToEvent:)]) {
            [self.delegate audioRecorder:self didPauseDueToEvent:DHAudioPauseEventInterruption];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(audioRecorder:willResumeAfterEvent:)]) {
            [self.delegate audioRecorder:self willResumeAfterEvent:DHAudioPauseEventInterruption];
        }
        [self resumeAudioQueue];
    }
}

- (void) audioRouteChanged:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(audioRecorder:didChangeAudioSessionRoute:)]) {
        [self.delegate audioRecorder:self
          didChangeAudioSessionRoute:notification.userInfo];
    }
}
@end

#pragma mark - Audio Input Callback
void HandleInputBuffer(
                       void                        *aqData,
                       AudioQueueRef               inAQ,
                       AudioQueueBufferRef         inBuffer,
                       const AudioTimeStamp        *inStartTime,
                       UInt32                      inNumPackets,
                       const AudioStreamPacketDescription *inPacketDesc
                       )
{
    DHAudioRecorder *recorder = (__bridge DHAudioRecorder *)aqData;
    if (inNumPackets == 0 && [recorder aqData].mDataFormat.mBytesPerPacket != 0) {
        inNumPackets = inBuffer->mAudioDataByteSize / [recorder aqData].mDataFormat.mBytesPerPacket;
    }
    if ([recorder.delegate respondsToSelector:@selector(audioRecorder:didRecordData:numberOfPackets:)]) {
        NSData *data = [NSData dataWithBytes:inBuffer->mAudioData
                                      length:inBuffer->mAudioDataByteSize];
        [recorder processPCMData:data
                 numberOfPackets:inNumPackets];
    }
    if ([recorder aqData].mIsRunning == 0) {
        return ;
    }
    AudioQueueEnqueueBuffer(recorder.aqData.mQueue, inBuffer, 0, NULL);
}

