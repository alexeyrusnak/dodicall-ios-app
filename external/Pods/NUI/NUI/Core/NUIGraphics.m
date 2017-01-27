//
//  NUIGraphics.m
//  NUIDemo
//
//  Created by Tom Benner on 11/25/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import "NUIGraphics.h"

@implementation NUIGraphics

+ (UIImage*)backButtonWithClass:(NSString*)className
{
    float borderWidth = 1;
    float cornerRadius = 7;
    float width = 50;
    float height = 32;
    float dWidth = width - borderWidth - 0.5;
    float dHeight = height - borderWidth - 0.5;
    float arrowWidth = 14;
    
    CAShapeLayer *shape       = [CAShapeLayer layer];
    shape.frame = CGRectMake(0, 0, width, height);
    shape.backgroundColor = [[UIColor clearColor] CGColor];
    shape.fillColor = [[UIColor clearColor] CGColor];
    shape.strokeColor = [[UIColor clearColor] CGColor];
    shape.lineWidth = 0;
    shape.lineCap = kCALineCapRound;
    shape.lineJoin = kCALineJoinRound;
    
    if ([NUISettings hasProperty:@"background-color" withClass:className]) {
        shape.fillColor = [[NUISettings getColor:@"background-color" withClass:className] CGColor];
    }
    if ([NUISettings hasProperty:@"background-color-top" withClass:className]) {
        shape.fillColor = [[NUISettings getColor:@"background-color-top" withClass:className] CGColor];
    }
    
    if ([NUISettings hasProperty:@"border-color" withClass:className]) {
        shape.strokeColor = [[NUISettings getColor:@"border-color" withClass:className] CGColor];
    }
    
    if ([NUISettings hasProperty:@"border-width" withClass:className]) {
        shape.lineWidth = [NUISettings getFloat:@"border-width" withClass:className];
    }
    
    if ([NUISettings hasProperty:@"corner-radius" withClass:className]) {
        cornerRadius = [NUISettings getFloat:@"corner-radius" withClass:className];
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, dWidth, dHeight - cornerRadius);
    CGPathAddArcToPoint(path, NULL, dWidth, dHeight, dWidth - cornerRadius, dHeight, cornerRadius);
    CGPathAddLineToPoint(path, NULL, arrowWidth, dHeight);
    CGPathAddLineToPoint(path, NULL, borderWidth + 0.5, height/2);
    CGPathAddLineToPoint(path, NULL, arrowWidth, borderWidth + 0.5);
    CGPathAddLineToPoint(path, NULL, dWidth - cornerRadius, borderWidth + 0.5);
    CGPathAddArcToPoint(path, NULL, dWidth, borderWidth, dWidth, borderWidth + cornerRadius, cornerRadius);
    CGPathAddLineToPoint(path, NULL, dWidth, dHeight - cornerRadius);
    shape.path = path;
    CFRelease(path);
    
    UIEdgeInsets insets = UIEdgeInsetsMake(1, arrowWidth + 5, 1, cornerRadius + 5);
    UIImage *image = [self caLayerToUIImage:shape];
    if ([image respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)]) {
        image = [image resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
    } else {
        image = [image resizableImageWithCapInsets:insets];
    }

    
    return image;
}

+ (CALayer*)roundedRectLayerWithClass:(NSString*)className size:(CGSize)size
{
    CALayer *layer = [CALayer layer];
    [layer setFrame:CGRectMake(0, 0, size.width, size.height)];
    [layer setMasksToBounds:YES];
    
    if ([NUISettings hasProperty:@"background-color" withClass:className]) {
        [layer setBackgroundColor:[[NUISettings getColor:@"background-color" withClass:className] CGColor]];
    }
    
    if ([NUISettings hasProperty:@"border-color" withClass:className]) {
        [layer setBorderColor:[[NUISettings getColor:@"border-color" withClass:className] CGColor]];
    }
    
    if ([NUISettings hasProperty:@"border-width" withClass:className]) {
        [layer setBorderWidth:[NUISettings getFloat:@"border-width" withClass:className]];
    }
    
    if ([NUISettings hasProperty:@"corner-radius" withClass:className]) {
        [layer setCornerRadius:[NUISettings getFloat:@"corner-radius" withClass:className]];
    }
    
    return layer;
}

+ (UIImage*)roundedRectImageWithClass:(NSString*)className size:(CGSize)size
{
  CALayer *layer = [self roundedRectLayerWithClass:className size:size];
  return [self roundedRectImageWithClass:className layer:layer];
}

+ (UIImage*)roundedRectImageWithClass:(NSString*)className layer:(CALayer*)layer
{
    float cornerRadius = [NUISettings getFloat:@"corner-radius" withClass:className];
    float insetLength = cornerRadius;
    
    if (cornerRadius < 5) {
        insetLength = 5;
    }
    insetLength += 3;
    
    UIEdgeInsets insets = UIEdgeInsetsMake(insetLength, insetLength, insetLength, insetLength) ;
    UIImage *image = [NUIGraphics caLayerToUIImage:layer];
    if ([image respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)]) {
        image = [image resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
    } else {
        image = [image resizableImageWithCapInsets:insets];
    }
    return image;
}

+ (CIColor*)uiColorToCIColor:(UIColor*)color
{
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return [CIColor colorWithRed:red green:green blue:blue];
}

+ (UIImage*)caLayerToUIImage:(CALayer*)layer
{
    UIScreen *screen = [UIScreen mainScreen];
    CGFloat scale = [screen scale];
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, scale);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (CALayer*)uiImageToCALayer:(UIImage*)image
{
    CALayer*    layer = [CALayer layer];
    CGFloat nativeWidth = CGImageGetWidth(image.CGImage);
    CGFloat nativeHeight = CGImageGetHeight(image.CGImage);
    CGRect      startFrame = CGRectMake(0.0, 0.0, nativeWidth, nativeHeight);
    layer.contents = (id)image.CGImage;
    layer.frame = startFrame;
    return layer;
}

+ (CIImage*)tintCIImage:(CIImage*)image withColor:(CIColor*)color
{
    CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
    CIImage *baseImage = image;
    
    [monochromeFilter setValue:baseImage forKey:@"inputImage"];        
    [monochromeFilter setValue:[CIColor colorWithRed:0.75 green:0.75 blue:0.75] forKey:@"inputColor"];
    [monochromeFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputIntensity"];
    
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CIMultiplyCompositing"];
    
    CIFilter *colorGenerator = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [colorGenerator setValue:color forKey:@"inputColor"];
    
    [compositingFilter setValue:[colorGenerator valueForKey:@"outputImage"] forKey:@"inputImage"];
    [compositingFilter setValue:[monochromeFilter valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];
    
    CIImage *outputImage = [compositingFilter valueForKey:@"outputImage"];
    
    return outputImage;
}

+ (UIImage*)colorImage:(UIColor*)color withFrame:(CGRect)frame
{
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0);
    [color setFill];
    UIRectFill(frame);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (CAGradientLayer*)gradientLayerWithTop:(id)topColor bottom:(id)bottomColor frame:(CGRect)frame
{
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.frame = frame;
    layer.colors = [NSArray arrayWithObjects:
                    (id)[topColor CGColor],
                    (id)[bottomColor CGColor], nil];
    layer.startPoint = CGPointMake(0.5f, 0.0f);
    layer.endPoint = CGPointMake(0.5f, 1.0f);
    return layer;
}

+ (UIImage*)gradientImageWithTop:(id)topColor bottom:(id)bottomColor frame:(CGRect)frame
{
    CAGradientLayer *layer = [self gradientLayerWithTop:topColor bottom:bottomColor frame:frame];
    UIGraphicsBeginImageContext([layer frame].size);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage*) createImageFromColor:(UIColor*) color ofRect:(CGRect)rect
{
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage*)changeImageColor:(UIImage*)image:(UIColor*)color {
    UIGraphicsBeginImageContextWithOptions(image.size, YES, [[UIScreen mainScreen] scale]);
    
    CGRect contextRect;
    contextRect.origin.x = 0.0f;
    contextRect.origin.y = 0.0f;
    contextRect.size = [image size];
    
    // Retrieve source image and begin image context
    CGSize itemImageSize = [image size];
    CGPoint itemImagePosition;
    itemImagePosition.x = ceilf((contextRect.size.width - itemImageSize.width) / 2);
    itemImagePosition.y = ceilf((contextRect.size.height - itemImageSize.height) );
    
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    // Setup shadow
    // Setup transparency layer and clip to mask
    CGContextBeginTransparencyLayer(c, NULL);
    CGContextScaleCTM(c, 1.0, -1.0);
    CGContextClipToMask(c, CGRectMake(itemImagePosition.x, -itemImagePosition.y, itemImageSize.width, -itemImageSize.height), [image CGImage]);
    
    // Fill and end the transparency layer
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(color.CGColor);
    CGColorSpaceModel model = CGColorSpaceGetModel(colorSpace);
    const CGFloat* colors = CGColorGetComponents(color.CGColor);
    
    if(model == kCGColorSpaceModelMonochrome) {
        CGContextSetRGBFillColor(c, colors[0], colors[0], colors[0], colors[1]);
    } else {
        CGContextSetRGBFillColor(c, colors[0], colors[1], colors[2], colors[3]);
    }
    contextRect.size.height = -contextRect.size.height;
    contextRect.size.height -= 15;
    CGContextFillRect(c, contextRect);
    CGContextEndTransparencyLayer(c);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    return img;
}

+ (UIImage*)resizeImage:(UIImage*)image:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
