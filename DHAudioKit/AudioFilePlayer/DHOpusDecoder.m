//
//  DHOpusDecoder.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHOpusDecoder.h"
#import "opus.h"

@interface DHOpusDecoder ()
@property (nonatomic, strong) dispatch_queue_t decodeQ;
@property (nonatomic, strong) NSMutableData *buffer;
@property (nonatomic, strong) NSMutableData *decodedData;
@property (nonatomic) OpusDecoder *decoder;
@property (nonatomic) int status;
@end

@implementation DHOpusDecoder

- (instancetype) initWithSampleRate:(int)sampleRate
                   numberOfChannels:(int)numberOfChannels
                     packetDuration:(float)packetDuration
                           delegate:(id<DHOpusDecoderDelegate>)delegate
{
    self = [super init];
    if (self) {
        _decodeQ = dispatch_queue_create("Opus Decode Queue", NULL);
        _buffer = [NSMutableData data];
        _decodedData = [NSMutableData data];
        _numberOfChannels = numberOfChannels;
        _sampleRate = sampleRate;
        _packetDuration = packetDuration;
        _status = OPUS_OK;
        _delegate = delegate;
        [self setupDecoder];
    }
    return self;
}

- (void) setupDecoder
{
    int error;
    _decoder = opus_decoder_create(self.sampleRate, self.numberOfChannels, &error);
    if (error != OPUS_OK) {
        NSLog(@"Error while creating opus decoder");
        self.status = error;
    }
}

- (void) setSampleRate:(int)sampleRate
{
    _sampleRate = sampleRate;
    [self setupDecoder];
}

- (void) setNumberOfChannels:(int)numberOfChannels
{
    _numberOfChannels = numberOfChannels;
    [self setupDecoder];
}

- (void) decodeOpusData:(NSData *)data
{
    if (self.status != OPUS_OK) {
        if ([self.delegate respondsToSelector:@selector(opusDecoder:failToDecodeDataWithError:)]) {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"info" : @"Error while setting up decoder"}];
            [self.delegate opusDecoder:self failToDecodeDataWithError:error];
        }
        return;
    }
    dispatch_async(self.decodeQ, ^{
        [self.buffer appendData:data];
        uint8_t *bytes = (uint8_t *)[self.buffer bytes];
        int offset = 0;
        while (true) {
            int length = bytes[offset];
            offset++;
            if (offset + length > [self.buffer length]) {
                offset--;
                break;
            }
            uint8_t *opusData = bytes + offset;
            opus_int16 *pcmBuffer = malloc(640);
            int decodedSamples = opus_decode(self.decoder, opusData, length, pcmBuffer, 320, 0);
            if (decodedSamples < 0) {
                self.status = -1;
                if ([self.delegate respondsToSelector:@selector(opusDecoder:failToDecodeDataWithError:)]) {
                    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"info" : @"Error while decoding data"}];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate opusDecoder:self failToDecodeDataWithError:error];
                    });
                }
                return;
            }
            NSData *pcmData = [NSData dataWithBytes:pcmBuffer length:decodedSamples * sizeof(opus_int16)];
            [self.decodedData appendData:pcmData];
            offset += length;
        }
        self.buffer = [NSMutableData dataWithBytes:bytes + offset length:[self.buffer length] - offset];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate opusDecoder:self didFinishDecodingWithResultPCMData:self.decodedData];
        });
    });
}

@end

