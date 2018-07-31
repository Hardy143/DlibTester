//
//  DlibWrapper.m
//  DlibTester
//
//  Created by Vicki Larkin on 05/07/2018.
//  Copyright © 2018 Vicki Hardy. All rights reserved.
//

#import "DlibWrapper.h"
#import <UIKit/UIKit.h>
#import <AVfoundation/AVfoundation.h>
#import "DlibTester-Swift.h"

#include <dlib/image_processing.h>
#include <dlib/image_io.h>

using namespace std;

int frameCounter = 1;
NSString *str = @"Facial Landmark Coordinates\n";

@interface DlibWrapper ()

@property (assign) BOOL prepared;

//+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end

@implementation DlibWrapper {
    dlib::shape_predictor sp;
}

//@protocol AVCaptureMetadataOutputObjectsDelegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
    }
    return self;
}

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
    
    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
}

- (NSString*)showString {
    return str;
}

- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects {
    
    if (SessionHandler.shared.isRecording) {
        
    }
    
    if (!self.prepared) {
        [self prepare];
    }
    
    dlib::array2d<dlib::bgr_pixel> img;
    
    // MARK: magic
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    // set_size expects rows, cols format
    img.set_size(height, width);
    
    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        
        position++;
    }
    
    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    

    // METADATA WAY
    // convert the face bounds list to dlib format
    std::vector<dlib::rectangle> convertedRectangles = [DlibWrapper convertCGRectValueArray:rects];
    
    //std::vector<dlib::rectangle> dets = detector(img);

    // METADATA WAY
     //for every detected face
    for (unsigned long j = 0; j < convertedRectangles.size(); ++j) {
    
        dlib::rectangle oneFaceRect = convertedRectangles[j];

        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);
        //....

        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            dlib::point p = shape.part(k);
            
            // appends the coordinates of each point to a string
            if (SessionHandler.shared.isRecording == true) {
                if (k == 0) {
                    str = [str stringByAppendingFormat:@"Frame %i:\nPoint %lu x: %ld y: %ld, ", frameCounter, (k + 1), shape.part(k).x(), shape.part(k).y()];
                    frameCounter += 1;
                } else if (k + 1 != 68) {
                    str = [str stringByAppendingFormat:@"Point %lu x: %ld y: %ld, ", (k + 1), shape.part(k).x(), shape.part(k).y()];
                } else {
                    str = [str stringByAppendingFormat:@"Point %lu x: %ld y: %ld\n\n", (k + 1), shape.part(k).x(), shape.part(k).y()];
                }
            }

            draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 255));
        }

    }
    
    
    // lets put everything back where it belongs
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // copy dlib image data back into samplebuffer
    img.reset();
    position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        baseBuffer[bufferLocation] = pixel.blue;
        baseBuffer[bufferLocation + 1] = pixel.green;
        baseBuffer[bufferLocation + 2] = pixel.red;
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        position++;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects {
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x;
        long top = rect.origin.y;
        long right = left + rect.size.width;
        long bottom = top + rect.size.height;
        dlib::rectangle dlibRect(left, top, right, bottom);
        
        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}

@end
