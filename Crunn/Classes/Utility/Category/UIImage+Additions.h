//
//  UIImage+Additions.h
//  Mobnotes
//
//  Created by Ashish Maheshwari on 2/24/10.
//  Copyright 2010 B24. All rights reserved.
//


@interface UIImage (RoundedCorner)
- (UIImage *)roundedCornerImage:(NSInteger)cornerSize borderSize:(NSInteger)borderSize;
+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size;
@end

@interface UIImage (Alpha)
- (BOOL)hasAlpha;
- (UIImage *)imageWithAlpha;
- (UIImage *)transparentBorderImage:(NSUInteger)borderSize;
- (UIImage *)drawImage:(UIImage*)image inFrame:(CGRect)rect;
@end


@interface UIImage(Resize)

- (UIImage*) scaleToSize:(CGSize)size;
- (UIImage*)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage*) grayscaleImage;

- (UIImage*)croppedImage:(CGRect)bounds;
- (UIImage*)thumbnailImage:(NSInteger)thumbnailSize
          transparentBorder:(NSUInteger)borderSize
               cornerRadius:(NSUInteger)cornerRadius
       interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage*)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage*)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resetOrientation;
+ (UIImage *)thumbnailFromVideoAtURL:(NSURL *)contentURL;
+(UIImage*)imageForStatus:(NSString*)status;
@end
