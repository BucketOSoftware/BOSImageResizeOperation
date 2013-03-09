//
//  BOSImageResizeOperationTests.m
//  BOSImageResizeOperationTests
//
//  Created by Michael Zole on 3/8/13.
//  Copyright (c) 2013 Bucket o' Software. All rights reserved.
//

#import "BOSImageResizeOperationTests.h"

#import "BOSImageResizeOperation.h"

@implementation BOSImageResizeOperationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    
    [super tearDown];
}

- (void)testBasicImageResize {
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Landscape_1" ofType:@"jpg"];
    UIImage* inputImage = [UIImage imageWithContentsOfFile:path];
    CGFloat inputAspectRatio = inputImage.size.width / inputImage.size.height;
    STAssertTrue(inputImage.size.width > 200.f && inputImage.size.height > 200.f, @"Image is too small to test scaling; did the test images change?");

    BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:inputImage];
    [op resizeToFitWithinSize:CGSizeMake(200.f, 200.f)];
    [op start];
    
    
    UIImage* outputImage = op.result;
    CGFloat outputAspectRatio = outputImage.size.width / outputImage.size.height;
    STAssertNotNil(outputImage, @"No result -- image resize failed");
    STAssertTrue(outputImage.size.width <= 200.f && outputImage.size.height <= 200.f, @"Image was not properly resized");
    STAssertEquals(inputAspectRatio, outputAspectRatio, @"Output image aspect ratio does not match input image (was %f, is now %f)", inputAspectRatio, outputAspectRatio);
    
    // TODO: visually compare images
}


- (void)testCropToAspectRatio {
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Landscape_1" ofType:@"jpg"];
    UIImage* inputImage = [UIImage imageWithContentsOfFile:path];
    CGFloat inputAspectRatio = inputImage.size.width / inputImage.size.height;
    STAssertEquals(inputAspectRatio, 600.f/450.f, @"Aspect ratio is different from expected; did the test images change?");
    
    BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:inputImage];
    [op cropToAspectRatioWidth:16 height:9];
    [op start];
    
    UIImage* outputImage = op.result;
    CGFloat outputAspectRatio = outputImage.size.width / outputImage.size.height;
    STAssertNotNil(outputImage, @"No result -- image resize failed");
    STAssertEqualsWithAccuracy(outputAspectRatio, 16.f/9.f, 0.01f, @"Image was cropped to the wrong aspect ratio");
    STAssertEquals(outputImage.size.width, inputImage.size.width, @"Image was cropped along its width when it shouldn't have been");
    STAssertEquals(outputImage.size.height, 338.f, @"Image was cropped to the wrong height");
    
    // TODO: visually compare images
}

@end
