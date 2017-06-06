//
//  DHOpusDecoder.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DHOpusDecoder;
@protocol DHOpusDecoderDelegate <NSObject>

- (void) opusDecoder:(DHOpusDecoder *)decoder didFinishDecodingWithResultPCMData:(NSData *)pcmData;

@optional
- (void) opusDecoder:(DHOpusDecoder *)decoder failToDecodeDataWithError:(NSError *)error;

@end

@interface DHOpusDecoder : NSObject

- (instancetype) initWithSampleRate:(int)sampleRate
                   numberOfChannels:(int)numberOfChannels
                     packetDuration:(float)packetDuration      //单位为秒，Opus 只支持2.5, 5, 10, 20, 40 or 60 ms
                           delegate:(id<DHOpusDecoderDelegate>)delegate;

@property (nonatomic, weak) id<DHOpusDecoderDelegate> delegate;
@property (nonatomic) int sampleRate;
@property (nonatomic) int numberOfChannels;
@property (nonatomic) float packetDuration;

- (void) decodeOpusData:(NSData *)data;

@end
