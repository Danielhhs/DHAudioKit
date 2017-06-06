//
//  DHMP3AudioConverter.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHMP3AudioConverter.h"
#import "lame.h"
@interface DHMP3AudioConverter() {
    lame_t lame;
}
@end

@implementation DHMP3AudioConverter

- (instancetype) initWithInputAudioFormat:(AudioStreamBasicDescription)inFormat
                        outputAudioFormat:(AudioStreamBasicDescription)outFormat
                                 delegate:(id<DHAudioConverterDelegate>)delegate
                            delegateQueue:(dispatch_queue_t)delegateQueue
{
    self = [super initWithInputAudioFormat:inFormat
                         outputAudioFormat:outFormat
                                  delegate:delegate
                             delegateQueue:delegateQueue];
    if (self) {
        encodeQ = dispatch_queue_create("Encode MP3 Queue", NULL);
        lame = lame_init();
        lame_set_in_samplerate(lame, inFormat.mSampleRate);
        lame_set_num_channels(lame, inFormat.mChannelsPerFrame);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
    }
    return self;
}


- (void) convertData:(NSData *)data numberOfPackets:(int)numberOfPackets
{
    if ([data length] == 0) {
        return;
    }
    
    self.numberOfPacketsReceived++;
    dispatch_async(encodeQ, ^{
        int numberOfSamples = (int)[data length] / sizeof(short) / self.inFormat.mChannelsPerFrame;
        
        int mp3BufferSize = (int)[data length] / sizeof(short) / self.inFormat.mChannelsPerFrame;
        unsigned char mp3Buffer[mp3BufferSize];
        
        int encodedBytes;
        
        if (self.inFormat.mChannelsPerFrame == 2) {
            encodedBytes = lame_encode_buffer_interleaved(lame, (short *)[data bytes], numberOfSamples, mp3Buffer, mp3BufferSize);
        } else {
            encodedBytes = lame_encode_buffer(lame, (short *)[data bytes], (short *)[data bytes], numberOfSamples, mp3Buffer, mp3BufferSize);
        }
        
        if (encodedBytes < 0) {
            [self reportErrorWithErrorCode:encodedBytes message:@"Fail to convert data"];
        } else {
            NSData *encodedData = [NSData dataWithBytes:mp3Buffer length:encodedBytes];
            dispatch_async(self.delegateQueue, ^{
                [self.delegate audioConverter:self didFinishConversionWithData:encodedData];
            });
            self.numberOfPacketsConverted++;
            [self finishConversionIfAllPacketsAreConverted];
        }
    });
}


- (void) cleanUpResource
{
    lame_close(lame);
}

@end
