//
//  DHAudioFilePlayer.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DHAudioAttributes.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, DHAudioPlayerStatus) {
    DHAudioPlayerStatusInitialized,
    DHAudioPlayerStatusReadyToPlay,
    DHAudioPlayerStatusConvertingData,
    DHAudioPlayerStatusWaitingForData,
    DHAudioPlayerStatusPlaying,
    DHAudioPlayerStatusPaused,
    DHAudioPlayerStatusStopped,
};

@class DHAudioFilePlayer;

@protocol DHAudioFilePlayerDelegate <NSObject>

@optional
- (void) audioPlayerIsReadyToPlay:(DHAudioFilePlayer *)audioPlayer;

- (void) audioPlayerDidFinishPlaying:(DHAudioFilePlayer *)audioPlayer
                        successfully:(BOOL)succuess;

- (void) audioPlayerDecodeErrorDidOccur:(DHAudioFilePlayer *)player
                                  error:(NSError *)error;

- (void) audioFilePlayer:(DHAudioFilePlayer *)audioPlayer
      didPauseDueToEvent:(DHAudioPauseEvent)event;

- (void) audioFilePlayer:(DHAudioFilePlayer *)audioPlayer
    willResumeAfterEvent:(DHAudioPauseEvent) event;

- (void) audioFilePlayer:(DHAudioFilePlayer *)audioPlayer
didChangeAudioSessionRoute:(NSDictionary *)userInfo;
@end

/**
 * DHAudioFilePlayer is a base class for audio file player; 
 * It uses AVAudioPlayer to enpower the audio play, so if the data is not supported by AVAudioPlayer, you need to subclass this class and do the decode yourself;
 * DHAudioFilePlayer supports only the type of data that is fully downloaded, and not incrementally adding data;
 */
@interface DHAudioFilePlayer : NSObject
/**
 * The path for the audio file to play;
 * Set either `filePath` or `data` can work;
 */
@property (nonatomic, strong) NSString *filePath;

/**
 * The data for the audio to play;
 * Set either `filePath` or `data` can work;
 */
@property (nonatomic, strong) NSData *data;

/**
 * The volume for the player; Between 0-1;
 */
@property (nonatomic) float volume;

/**
 * Packet duration;
 * Opus format will need this value to play the audio correctly;
 */
@property (nonatomic) NSTimeInterval packetDuration;

/**
 * The audio format for the audio to play; It has to be excatly the same as the data, otherwise there will be errors;
 */
@property (nonatomic) AudioStreamBasicDescription audioFormat;

/**
 * Cuurent status for the player, see `DHAudioPlayerStatus`
 */
@property (nonatomic) DHAudioPlayerStatus status;

/**
 * The delegate to handle player events;
 */
@property (nonatomic, weak) id<DHAudioFilePlayerDelegate> delegate;

/**
 * Convenience Initializer
 * @param filePath the file path for the audio to play
 * @param audioFormat the audio format for the audio
 * @param delegate the delegate
 */
- (instancetype) initWithFilePath:(NSString *) filePath
                      audioFormat:(AudioStreamBasicDescription)audioFormat
                         delegate:(id<DHAudioFilePlayerDelegate>)delegate;

/**
 * Convenience Initializer
 * @param filePath the file path for the audio to play
 * @param packetDuration the packetDuration for opus format
 * @param audioFormat the audio format for the audio
 * @param delegate the delegate
 */
- (instancetype) initWithFilePath:(NSString *) filePath
                   packetDuration:(NSTimeInterval)packetDuration
                      audioFormat:(AudioStreamBasicDescription)audioFormat
                         delegate:(id<DHAudioFilePlayerDelegate>)delegate;

/**
 * Convenience Initializer
 * @param data the audio data to play
 * @param audioFormat the audio format for the audio
 * @param delegate the delegate
 */
- (instancetype) initWithData:(NSData *) data
                  audioFormat:(AudioStreamBasicDescription)audioFormat
                     delegate:(id<DHAudioFilePlayerDelegate>)delegate;

/**
 * Convenience Initializer
 * @param data the audio data to play
 * @param packetDuration the packetDuration for opus format
 * @param audioFormat the audio format for the audio
 * @param delegate the delegate
 */
- (instancetype) initWithData:(NSData *) data
               packetDuration:(NSTimeInterval)packetDuration
                  audioFormat:(AudioStreamBasicDescription)audioFormat
                     delegate:(id<DHAudioFilePlayerDelegate>)delegate;

/**
 * Start playing
 */
- (void) play;

/**
 * Pause playing
 */
- (void) pause;

/**
 * Resume playing
 */
- (void) resume;

/**
 * Stop playing
 */
- (void) stop;

/**
 * Duration of the audio file;
 */
- (NSTimeInterval) duration;

/**
 * Set current playing time;
 */
- (void)setCurrentTime:(NSTimeInterval)currentTime;

#pragma mark - For Data that could not be played directly

/**
 * If the audio data could not be played by AVAudioPlayer, like Opus, you need to override `setupPlayerWithFile` or `setupPlayerWithData`,decode the data in one of these two methods, and call `updateWithPlayableData` when the data is fully decoded.
 */
- (void) setupPlayerWithFile:(NSString *)filePath;
- (void) setupPlayerWithData:(NSData *)data;
- (void) updateWithPlayableData:(NSData *)playableData;

/**
 * If the data needs to be decoded synchronously, update the data by calling this method when decode is done.
 */
- (NSData *) playableDataWithData:(NSData *)data;

@end
