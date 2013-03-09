//
//  BOSImageResizeOperation.m
//  BOSImageResizeOperation
//
//  Created by Alex Michaud on 3/08/13.
//  Copyright 2013 Bucket o' Software. All rights reserved.
//

#import "BOSImageResizeOperation.h"

#import <QuartzCore/QuartzCore.h>


// Return the scale that will proportionally fit toBeScaled within container
static inline double scaleToFit(CGSize container, CGSize toBeScaled) {
    return MIN((double)container.width / (double)toBeScaled.width, (double)container.height / (double)toBeScaled.height);
}

static inline CGFloat degrees2radians(CGFloat degrees) {
    return degrees * M_PI / 180.0;
}


@interface BOSImageResizeOperation ()

@property (nonatomic,assign) CGSize fitWithin;
@property (nonatomic,strong) NSString* inputPath;
@property (nonatomic,strong) NSString* writePath;
@property (nonatomic,strong) UIImage* imageToResize;
@property (nonatomic,readwrite,strong) UIImage* result;
@property (nonatomic,assign) CGFloat cropToAspectRatio; // TODO: determine if using a double would make a difference

@end


@implementation BOSImageResizeOperation


#pragma mark - Initialization

- (id)initWithPath:(NSString*)inputPath {
    self = [super init];
    if (self) {
        self.inputPath = [inputPath copy];
    }
    
    return self;
}


- (id)initWithImage:(UIImage*)image {
    self = [super init];
    if (self) {
        // Initialization code here.
        self.imageToResize = [image copy];
    }
    
    return self;
}


#pragma mark - Configuration

- (void)resizeToFitWithinSize:(CGSize)fitWithin {
    self.fitWithin = fitWithin;
}


- (void)cropToAspectRatioWidth:(CGFloat)width height:(CGFloat)height {
    self.cropToAspectRatio = width / height;
}


- (void)writeResultToPath:(NSString*)outputPath {
    self.writePath = outputPath;
}


#pragma mark -

- (void)doResize {
    if (!self.imageToResize) {
        // TODO: set error
        // No image to resize
        return;
    }
    
    // The size of the image that will be output
    CGSize outputCanvasSize = CGSizeZero;
    // The size the input image will be when drawn to the canvas. Default to same as input image size
    CGSize outputImageSize = self.imageToResize.size;
    
    if (!CGSizeEqualToSize(CGSizeZero, self.fitWithin)) {
        // If we've been asked to "fit within", don't make it any bigger
        
        CGFloat scale = MIN(1.0f, scaleToFit(self.fitWithin, self.imageToResize.size));
        outputImageSize = CGSizeMake(roundf(self.imageToResize.size.width * scale), roundf(self.imageToResize.size.height * scale));
    }
    
    outputCanvasSize = outputImageSize;
    if (self.cropToAspectRatio) {
        // We've been asked to crop, so make the canvas match that aspect ratio
        // We use outputImageSize to determine the aspect ratio because rounding might change the result slightly
        double inputAspectRatio = (double)outputImageSize.width / (double)outputImageSize.height;
        if (inputAspectRatio > self.cropToAspectRatio) {
            // Image is too wide -- crop width
            outputCanvasSize.width = roundf(outputImageSize.height * self.cropToAspectRatio);
        } else if (inputAspectRatio < self.cropToAspectRatio) {
            // Image is too tall -- crop height
            outputCanvasSize.height = roundf(outputImageSize.width / self.cropToAspectRatio);
        }
        // If we don't hit either of those two blocks, the output size is already in the right aspect ratio
    }
    
    CGPoint canvasOffset = CGPointMake((outputCanvasSize.width - outputImageSize.width) / 2.f,
                                       (outputCanvasSize.height - outputImageSize.height) / 2.f);
    
//    NSLog(@"Resizing %@ -> %@, canvas offset %@", NSStringFromCGSize(self.imageToResize.size), NSStringFromCGSize(outputCanvasSize), NSStringFromCGPoint(canvasOffset));
    
    CGImageRef imageRef = [self.imageToResize CGImage];
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    
    // This is true, but commented because right now I'm not sure what we can do about it
    /*
    if (CGImageGetAlphaInfo(imageRef) != kCGImageAlphaNoneSkipLast) {
        NSLog(@"Warning: alpha is not kCGImageAlphaNoneSkipLast, resizing may be slower");
    }
     */
    
    NSUInteger bytesPerRow = outputCanvasSize.width * 4;
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                outputCanvasSize.width,
                                                outputCanvasSize.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                bytesPerRow,
                                                colorSpaceInfo,
                                                bitmapInfo);
    
    if (bitmap == NULL) {
        // TODO: set error
        return;
    }
    
    switch (self.imageToResize.imageOrientation) {
        case UIImageOrientationLeft:
            // home button: up
            CGContextRotateCTM (bitmap, degrees2radians(90.f));
            CGContextTranslateCTM (bitmap, 0, -(outputCanvasSize.width));
            CGContextDrawImage(bitmap, CGRectMake(canvasOffset.y, canvasOffset.x, outputImageSize.height, outputImageSize.width), imageRef);
            break;
        case UIImageOrientationRight:
            // rotate counterclockwise 90 degrees / home button down
            CGContextRotateCTM (bitmap, degrees2radians(-90.f));
            CGContextTranslateCTM (bitmap, -(outputCanvasSize.height), 0);
            CGContextDrawImage(bitmap, CGRectMake(canvasOffset.y, canvasOffset.x, outputImageSize.height, outputImageSize.width), imageRef);
            break;
        case UIImageOrientationDown:
            // rotate 180 degrees / home button at left
            CGContextTranslateCTM (bitmap, outputCanvasSize.width, outputCanvasSize.height);
            CGContextRotateCTM (bitmap, degrees2radians(-180.f));
            // No break -- uses the same draw call as Up
        case UIImageOrientationUp:
            // no rotation / home button at right
            CGContextDrawImage(bitmap, CGRectMake(canvasOffset.x, canvasOffset.y, outputImageSize.width, outputImageSize.height), imageRef);
            break;
        default:
            // TODO: set the error and/or support other orientations
            NSLog(@"Orientation not supported: %d", self.imageToResize.imageOrientation);
            CGContextRelease(bitmap);
            return;
    }
    
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    CGContextRelease(bitmap);
    
    // Thread-safe as of iOS 4
    self.result = [[UIImage alloc] initWithCGImage:ref];
    self.imageToResize = nil;
    
    CGImageRelease(ref);
}



- (void)main {
    @autoreleasepool {
        // TODO: make better
        NSAssert((self.inputPath != nil) != (self.imageToResize != nil), @"No image specified to resize");
        
        if (self.inputPath) {
            self.imageToResize = [UIImage imageWithContentsOfFile:self.inputPath];
            if (self.imageToResize == nil) {
                // TODO: set error
                NSLog(@"Couldn't load image");
                return;
            }
        }
        
        [self doResize];
        
        if (self.writePath) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.writePath]) {
                NSLog(@"WARNING: Overwriting file at %@", self.writePath);
            }
            
            NSData* outputData = nil;
            if ([[self.writePath lowercaseString] hasSuffix:@".jpg"]) {
                // JPEG quality defaults to 0.8
                outputData = UIImageJPEGRepresentation(self.result, self.JPEGcompressionQuality ? self.JPEGcompressionQuality : 0.8f);
            } else {
                // For now, we default to writing a PNG if we don't recognize the extension
                outputData = UIImagePNGRepresentation(self.result);
            }
            
            NSError* writeError = nil;
            [outputData writeToFile:self.writePath options:NSDataWritingAtomic error:&writeError];
            // TODO: wrap the error
            if (writeError) {
                NSLog(@"Couldn't write to %@: %@", self.writePath, [writeError localizedDescription]);
            }
        }
    }
}

@end
