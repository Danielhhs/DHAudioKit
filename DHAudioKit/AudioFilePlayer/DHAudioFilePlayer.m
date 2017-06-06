//
//  DHAudioFilePlayer.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAudioFilePlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface DHAudioFilePlayer ()<AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic) NSTimeInterval startPlayingTime;
@property (nonatomic) NSTimeInterval interruptedTime;
@end

@implementation DHAudioFilePlayer
#pragma mark - Set up
- (instancetype) initWithFilePath:(NSString *)filePath
                      audioFormat:(AudioStreamBasicDescription)audioFormat
                         delegate:(id<DHAudioFilePlayerDelegate>)delegate
{
    return [self initWithFilePath:filePath
                   packetDuration:0
                      audioFormat:audioFormat
                         delegate:delegate];
}

- (instancetype) initWithFilePath:(NSString *)filePath
                   packetDuration:(NSTimeInterval)packetDuration
                      audioFormat:(AudioStreamBasicDescription)audioFormat
                         delegate:(id<DHAudioFilePlayerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _filePath = filePath;
        _audioFormat = audioFormat;
        _packetDuration = packetDuration;
        _status = DHAudioPlayerStatusInitialized;
        _delegate = delegate;
        [self setupPlayerWithFile:filePath];
    }
    return self;
}

- (instancetype) initWithData:(NSData *)data
                  audioFormat:(AudioStreamBasicDescription)audioFormat
                     delegate:(id<DHAudioFilePlayerDelegate>)delegate
{
    return [self initWithData:data
               packetDuration:0
                  audioFormat:audioFormat
                     delegate:delegate];
}

- (instancetype) initWithData:(NSData *)data
               packetDuration:(NSTimeInterval)packetDuration
                  audioFormat:(AudioStreamBasicDescription)audioFormat
                     delegate:(id<DHAudioFilePlayerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _data = data;
        _audioFormat = audioFormat;
        _packetDuration = packetDuration;
        _status = DHAudioPlayerStatusInitialized;
        _delegate = delegate;
        [self setupPlayerWithData:data];
    }
    return self;
}

- (void) setFilePath:(NSString *)filePath
{
    _filePath = filePath;
    [self setupPlayerWithFile:filePath];
}

- (void) setupPlayerWithFile:(NSString *) filePath
{
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    _status = DHAudioPlayerStatusConvertingData;
    [self updateWithPlayableData:[self playableDataWithData:data]];
    _status = DHAudioPlayerStatusReadyToPlay;
}

- (void) setupPlayerWithData:(NSData *) data
{
    _status = DHAudioPlayerStatusConvertingData;
    [self updateWithPlayableData:[self playableDataWithData:data]];
    _status = DHAudioPlayerStatusReadyToPlay;
}

- (void) updateWithPlayableData:(NSData *)data
{
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    if (error) {
        if ([self.delegate respondsToSelector:@selector(audioPlayerDecodeErrorDidOccur:error:)]) {
            [self.delegate audioPlayerDecodeErrorDidOccur:self error:error];
        }
        return;
    }
    self.player.delegate = self;
    [self.player prepareToPlay];
    if ([self.delegate respondsToSelector:@selector(audioPlayerIsReadyToPlay:)]) {
        [self.delegate audioPlayerIsReadyToPlay:self];
    }
    if (self.status == DHAudioPlayerStatusWaitingForData) {
        self.status = DHAudioPlayerStatusReadyToPlay;
        [self play];
    }
}

- (NSData *) playableDataWithData:(NSData *)data
{
    return data;
}

#pragma mark - Actions
- (void) play
{
    if (self.status != DHAudioPlayerStatusConvertingData) {
        [self addInterruptionObservers];
        [self.player play];
        self.startPlayingTime = CACurrentMediaTime();
        self.status = DHAudioPlayerStatusPlaying;
    } else {
        self.status = DHAudioPlayerStatusWaitingForData;
    }
}

- (void) pause
{
    if (self.status != DHAudioPlayerStatusPlaying) {
        return ;
    }
    [self pausePlayer];
    [self removeObserver];
}

- (void) pausePlayer
{
    [self.player pause];
    self.status = DHAudioPlayerStatusPaused;
}

- (void) stop
{
    [self.player stop];
    self.status = DHAudioPlayerStatusStopped;
    [self removeObserver];
}

- (void) resume
{
    if (self.status != DHAudioPlayerStatusPaused) {
        return ;
    }
    [self addInterruptionObservers];
    [self resumePlayer];
}

- (void) resumePlayer
{
    [self.player play];
    self.status = DHAudioPlayerStatusPlaying;
}

- (void) addInterruptionObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void) removeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setVolume:(float)volume
{
    _volume = volume;
    [self.player setVolume:volume];
}

- (NSTimeInterval) duration
{
    return [self.player duration];
}

- (void) setCurrentTime:(NSTimeInterval)currentTime
{
    [self.player setCurrentTime:currentTime];
}

#pragma mark - AVAudioPlayerDelegate
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if ([self.delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying:successfully:)]) {
        [self.delegate audioPlayerDidFinishPlaying:self successfully:flag];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    if ([self.delegate respondsToSelector:@selector(audioPlayerDecodeErrorDidOccur:error:)]) {
        [self.delegate audioPlayerDecodeErrorDidOccur:self error:error];
    }
}

- (void) audioInterrupt:(NSNotification *) notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *interruptionType = userInfo[AVAudioSessionInterruptionTypeKey];
    
    if ([interruptionType intValue] == AVAudioSessionInterruptionTypeBegan) {
        [self pausePlayer];
        self.interruptedTime = CACurrentMediaTime() - self.startPlayingTime;
        if ([self.delegate respondsToSelector:@selector(audioFilePlayer:didPauseDueToEvent:)]) {
            [self.delegate audioFilePlayer:self didPauseDueToEvent:DHAudioPauseEventInterruption];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(audioFilePlayer:willResumeAfterEvent:)]) {
            [self.delegate audioFilePlayer:self willResumeAfterEvent:DHAudioPauseEventInterruption];
        }
        [self setCurrentTime:self.interruptedTime];
        [self resumePlayer];
    }
}

- (void) audioRouteChanged:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(audioFilePlayer:didChangeAudioSessionRoute:)]) {
        [self.delegate audioFilePlayer:self
            didChangeAudioSessionRoute:notification.userInfo];
    }
}
@end
