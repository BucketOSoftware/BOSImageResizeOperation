//
//  BOSImageResizeOperation.h
//  BOSImageResizeOperation
//
//  Created by Alex Michaud on 3/08/13.
//  Copyright 2013 Bucket o' Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BOSImageResizeOperation : NSOperation

// The resized image, or nil if an error occurred
@property (nonatomic,readonly,strong) UIImage* result;

// TODO: If the resize fails, this will describe the error
//@property (nonatomic,strong) NSError* error;

- (id)initWithImage:(UIImage*)image;
- (id)initWithPath:(NSString*)inputPath;

- (void)resizeToFitWithinSize:(CGSize)fitWithinSize;
- (void)cropToAspectRatioWidth:(CGFloat)width height:(CGFloat)height;
- (void)writeResultToPath:(NSString*)outputPath;

// Options
@property (nonatomic,assign) CGFloat JPEGcompressionQuality;

@end
