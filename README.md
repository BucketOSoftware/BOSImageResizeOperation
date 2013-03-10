BOSImageResizeOperation
=======================

An Objective-C operation to resize your images correctly and quickly. 


## Features

* Thread safe: as a subclass of NSOperation, BOSImageResizeOperation can easily be used with an NSOperationQueue to resize images without blocking the current thread.
* Designed for the common use case: resizes images proportionally to fit within a given size.
* Can also crop to fit a given aspect ratio.
* Respects EXIF/UIImage orientation.

## Requirements

BOSImageResizeOperation uses ARC and has been tested with iOS 4.3 and above.

## Installation

### Manual

Add `BOSImageResizeOperation.h` and `BOSImageResizeOperation.m` to your project. You'll need to enable ARC for your project, or just for `BOSImageResizeOperation.m`, which is left as an exercise for the reader.

### CocoaPods

We're not in the CocoaPods repository yet, but you can install the latest version by adding the following line to your `Podfile`:

    pod 'BOSImageResizeOperation', :git => 'git://github.com/BucketOSoftware/BOSImageResizeOperation.git'


## Usage

1. Create an instance of BOSImageResizeOperation and initialize it with either a path to a file or a UIImage object.
	
	```objective-c
	// We already have the image in memory, e.g. from UIImagePickerController
	UIImage* image = info[UIImagePickerControllerOriginalImage];
	BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:image];
	```

	```objective-c
	// We don't have the image in memory; it will be loaded on a background thread
	NSString* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	NSString* inputPath = [documentsPath stringByAppendingPathComponent:@"large_image.jpg"];
	BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithPath:inputPath];	
	```

2. Specify how you'd like the image resized. Any of these can be combined.
	
	**Resize** the image proportionally so it fits within the given size:
	```objective-c
	[op resizeToFitWithinSize:CGSizeMake(200.f, 200.f)];
	```

	**Crop** the image to the given aspect ratio:
	```objective-c
	[op cropToAspectRatioWidth:16 height:9];
	```

	**Write** the image to disk when finished (optional). The format will be PNG by default and JPEG if the output path ends in ".jpg". For JPEG output, the ```JPEGcompressionQuality``` property can be used to specify compression quality, from 0.0 to 1.0. The default is 0.8.

	```objective-c
	NSString* outputPath = [documentsPath stringByAppendingPathComponent:@"small_image.jpg"];
	op.JPEGcompressionQuality = 0.5;
	[op writeResultToPath:outputPath];
	```
	
3. Start the operation.
	
	On the current thread (for example, if we're already on a background thread):
	```objective-c
	[op start];
	```

	In the background, using an NSOperationQueue:
	```objective-c
	NSOperationQueue* queue = [[NSOperationQueue alloc] init];

	// Avoid a retain cycle (ARC & iOS 5+)
	__weak BOSImageResizeOperation* weakOp = op;

	[op setCompletionBlock:^{
		UIImage* smallerImage = weakOp.result;
	}];

	[queue addOperation:op];
	```

	In the background, using Grand Central Dispatch:
	```objective-c
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[op start];
		UIImage* smallerImage = op.result;
	});
	```

4. Do something with the image. If an error ocurred while resizing the image, the ```result``` property will be nil.

## TODO

* More image resizing options
* Better error handling
* Support for mirrored orientations
* More extensive tests

## Brought to you by

BOSImageResizeOperation was written by [Alex Michaud](http://github.com/zole), based on techniques cobbled together from all over the Internet and Stack Overflow. Contributions are welcome and will help create a utopia where all iOS apps resize images the right way, no matter what edge cases are uncovered. Follow or say hi on Twitter: [@bucketosoftware](https://twitter.com/bucketosoftware)

## License

BOSImageResizeOperation is available under the MIT license. See the LICENSE file for more information.
