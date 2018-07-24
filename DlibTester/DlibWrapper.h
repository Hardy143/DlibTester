//
//  DlibWrapper.h
//  DlibTester
//
//  Created by Vicki Larkin on 05/07/2018.
//  Copyright © 2018 Vicki Hardy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface DlibWrapper : NSObject

- (instancetype)init;
- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects;
- (void)prepare;

@end
