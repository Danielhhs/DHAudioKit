//
//  DHOpusAudioConverter.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHOpusAudioConverter.h"
#import "opus.h"

#define OPUS_OUTPUT_BUFFER_SIZE 4000
#define OPUS_DEFAULT_BITRATE 27800

@interface DHOpusAudioConverter () {
}
@property (nonatomic) OpusEncoder *encoder;
@property (nonatomic) int pcmBufferSize;
@property (nonatomic, strong) NSMutableData *buffer;    //用来确保每次encode的PCM frame大小都为固定为可识别的frameSize
@property (nonatomic) NSInteger numberOfBytesReceived;
@end

@implementation DHOpusAudioConverter

#pragma mark - Initialization
- (instancetype) initWithInputAudioFormat:(AudioStreamBasicDescription)inFormat
                        outputAudioFormat:(AudioStreamBasicDescription)outFormat
                                 delegate:(id<DHAudioConverterDelegate>)delegate
                            delegateQueue:(dispatch_queue_t)delegateQueue
{
    self = [super initWithInputAudioFormat:inFormat
                         outputAudioFormat:outFormat
                                  delegate:delegate
                             delegateQueue:delegateQueue];
    if (self){
        int error;
        _encoder = opus_encoder_create(outFormat.mSampleRate, outFormat.mChannelsPerFrame, OPUS_APPLICATION_VOIP, &error);
        if (error != OPUS_OK) {
            [self reportErrorWithErrorCode:error message:@"Fail to create converter"];
            return nil;
        }
        
        opus_encoder_ctl(self.encoder, OPUS_SET_VBR(1));
        opus_encoder_ctl(self.encoder, OPUS_SET_BITRATE(self.bitRate));
        opus_encoder_ctl(self.encoder, OPUS_SET_COMPLEXITY(8));
        opus_encoder_ctl(self.encoder, OPUS_SET_SIGNAL(OPUS_SIGNAL_VOICE));
        
        _pcmBufferSize = outFormat.mSampleRate * 0.02 * sizeof(opus_int16) * outFormat.mChannelsPerFrame;  //20ms per frame
        _buffer = [NSMutableData data];
        encodeQ = dispatch_queue_create("Opus Encode Queue", NULL);
        outBufferSize = OPUS_OUTPUT_BUFFER_SIZE;
    }
    return self;
}

#pragma mark - Audio Conversion
- (void) convertData:(NSData *)data numberOfPackets:(int)numberOfPackets
{
    if ([data length] == 0) {
        return;
    }
    self.numberOfBytesReceived += [data length];
    if (self.numberOfBytesReceived >= self.pcmBufferSize) {
        self.numberOfPacketsReceived++;
        self.numberOfBytesReceived -= self.pcmBufferSize;
    }
    dispatch_async(encodeQ, ^{
        [self.buffer appendData:data];
        if ([self.buffer length] < self.pcmBufferSize) {
            return;
        }
        opus_int16 *pcmFrame = malloc(self.pcmBufferSize);
        memcpy(pcmFrame, [self.buffer bytes], self.pcmBufferSize);
        
        if ([self.buffer length] > self.pcmBufferSize) {
            self.buffer = [NSMutableData dataWithBytes:[self.buffer bytes] + self.pcmBufferSize length:[self.buffer length] - self.pcmBufferSize];
        } else {
            self.buffer = [NSMutableData data];
        }
        
        outBuffer = malloc(outBufferSize * sizeof(uint8_t));
        int encodedBytes = opus_encode(self.encoder, pcmFrame, self.pcmBufferSize / sizeof(opus_int16) / self.outFormat.mChannelsPerFrame, outBuffer, OPUS_OUTPUT_BUFFER_SIZE);
        NSMutableData *encodedData = [[NSMutableData alloc] initWithCapacity:outBufferSize];
        
        [encodedData appendBytes:&encodedBytes length:1];
        [encodedData appendBytes:outBuffer length:encodedBytes];
        dispatch_async(self.delegateQueue, ^{
            [self.delegate audioConverter:self didFinishConversionWithData:encodedData];
            self.numberOfPacketsConverted++;
            [self finishConversionIfAllPacketsAreConverted];
        });
    });
}

- (void) setBitRate:(UInt32)bitRate
{
    [super setBitRate:bitRate];
    opus_encoder_ctl(self.encoder, OPUS_SET_BITRATE(bitRate));
}

- (UInt32) bitRate
{
    if ([super bitRate] == 0) {
        return OPUS_DEFAULT_BITRATE;
    }
    return [super bitRate];
}

- (void) cleanUpResource
{
    opus_encoder_destroy(self.encoder);
}
@end

