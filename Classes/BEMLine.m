//
//  BEMLine.m
//  SimpleLineGraph
//
//  Created by Bobo on 12/27/13. Updated by Sam Spencer on 1/11/14.
//  Copyright (c) 2013 Boris Emorine. All rights reserved.
//  Copyright (c) 2014 Sam Spencer.
//

#import "BEMLine.h"
#import "BEMSimpleLineGraphView.h"

#import "UIBezierPath+Interpolation.h"

#if CGFLOAT_IS_DOUBLE
#define CGFloatValue doubleValue
#else
#define CGFloatValue floatValue
#endif


@interface BEMLine()

@property (nonatomic, strong) NSMutableArray *points;

@end

@implementation BEMLine

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        _enableLeftReferenceFrameLine = YES;
        _enableBottomReferenceFrameLine = YES;
        _interpolateNullValues = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    //----------------------------//
    //---- Draw Refrence Lines ---//
    //----------------------------//
    UIBezierPath *verticalReferenceLinesPath = [UIBezierPath bezierPath];
    UIBezierPath *horizontalReferenceLinesPath = [UIBezierPath bezierPath];
    UIBezierPath *referenceFramePath = [UIBezierPath bezierPath];

    verticalReferenceLinesPath.lineCapStyle = kCGLineCapButt;
    verticalReferenceLinesPath.lineWidth = 0.7;

    horizontalReferenceLinesPath.lineCapStyle = kCGLineCapButt;
    horizontalReferenceLinesPath.lineWidth = 0.7;

    referenceFramePath.lineCapStyle = kCGLineCapButt;
    referenceFramePath.lineWidth = 0.7;

    if (self.enableRefrenceFrame == YES) {
        if (self.enableBottomReferenceFrameLine) {
            // Bottom Line
            [referenceFramePath moveToPoint:CGPointMake(0, self.frame.size.height)];
            [referenceFramePath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        }

        if (self.enableLeftReferenceFrameLine) {
            // Left Line
            [referenceFramePath moveToPoint:CGPointMake(0+self.referenceLineWidth/4, self.frame.size.height)];
            [referenceFramePath addLineToPoint:CGPointMake(0+self.referenceLineWidth/4, 0)];
        }

        if (self.enableTopReferenceFrameLine) {
            // Top Line
            [referenceFramePath moveToPoint:CGPointMake(0+self.referenceLineWidth/4, 0)];
            [referenceFramePath addLineToPoint:CGPointMake(self.frame.size.width, 0)];
        }

        if (self.enableRightReferenceFrameLine) {
            // Right Line
            [referenceFramePath moveToPoint:CGPointMake(self.frame.size.width - self.referenceLineWidth/4, self.frame.size.height)];
            [referenceFramePath addLineToPoint:CGPointMake(self.frame.size.width - self.referenceLineWidth/4, 0)];
        }
    }

    if (self.enableRefrenceLines == YES) {
        if (self.arrayOfVerticalRefrenceLinePoints.count > 0) {
            for (NSNumber *xNumber in self.arrayOfVerticalRefrenceLinePoints) {
                CGFloat xValue;
                if (self.verticalReferenceHorizontalFringeNegation != 0.0) {
                    if ([self.arrayOfVerticalRefrenceLinePoints indexOfObject:xNumber] == 0) { // far left reference line
                        xValue = [xNumber floatValue] + self.verticalReferenceHorizontalFringeNegation;
                    } else if ([self.arrayOfVerticalRefrenceLinePoints indexOfObject:xNumber] == [self.arrayOfVerticalRefrenceLinePoints count]-1) { // far right reference line
                        xValue = [xNumber floatValue] - self.verticalReferenceHorizontalFringeNegation;
                    } else xValue = [xNumber floatValue];
                } else xValue = [xNumber floatValue];

                CGPoint initialPoint = CGPointMake(xValue, self.frame.size.height);
                CGPoint finalPoint = CGPointMake(xValue, 0);

                [verticalReferenceLinesPath moveToPoint:initialPoint];
                [verticalReferenceLinesPath addLineToPoint:finalPoint];
            }
        }

        if (self.arrayOfHorizontalRefrenceLinePoints.count > 0) {
            for (NSNumber *yNumber in self.arrayOfHorizontalRefrenceLinePoints) {
                CGPoint initialPoint = CGPointMake(0, [yNumber floatValue]);
                CGPoint finalPoint = CGPointMake(self.frame.size.width, [yNumber floatValue]);

                [horizontalReferenceLinesPath moveToPoint:initialPoint];
                [horizontalReferenceLinesPath addLineToPoint:finalPoint];
            }
        }
    }

    // Image context starts here
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    
    //----------------------------//
    //----- Draw Average Line ----//
    //----------------------------//
    UIBezierPath *averageLinePath = [UIBezierPath bezierPath];
    if (self.averageLine.enableAverageLine == YES) {
        averageLinePath.lineCapStyle = kCGLineCapButt;
        averageLinePath.lineWidth = self.averageLine.width;

        CGPoint initialPoint = CGPointMake(0, self.averageLineYCoordinate);
        CGPoint finalPoint = CGPointMake(self.frame.size.width, self.averageLineYCoordinate);

        [averageLinePath moveToPoint:initialPoint];
        [averageLinePath addLineToPoint:finalPoint];
    }
    
    //----------------------------//
    //------ Draw Graph Line -----//
    //----------------------------//
    // LINE
    UIBezierPath *line = [UIBezierPath bezierPath];
    UIBezierPath *fillTop;
    UIBezierPath *fillBottom;

    self.points = [NSMutableArray arrayWithCapacity:self.arrayOfPoints.count];
    for (int i = 0; i < self.arrayOfPoints.count; i++) {
        CGPoint value = CGPointMake([self.arrayOfXValues[i] CGFloatValue], [self.arrayOfPoints[i] CGFloatValue]);
        if (value.y != BEMNullGraphValue || !self.interpolateNullValues) {
            [self.points addObject:[NSValue valueWithCGPoint:value]];
        }
    }

    BOOL bezierStatus = self.bezierCurveIsEnabled;
    if (self.arrayOfPoints.count <= 2 && self.bezierCurveIsEnabled == YES) bezierStatus = NO;
    
    if (!self.disableMainLine && bezierStatus) {
        line = [BEMLine quadCurvedPathWithPoints:self.points];
    } else if (!self.disableMainLine && !bezierStatus) {
        line = [BEMLine linesToPoints:self.points];
    } else {
        // Remains empty path
    }
    
    fillBottom = [self bottomFillPath];
    fillTop = [self topFillPath];

    //----------------------------//
    //----- Draw Fill Colors -----//
    //----------------------------//
    [self.topColor set];
    [fillTop fillWithBlendMode:kCGBlendModeNormal alpha:self.topAlpha];

    [self.bottomColor set];
    [fillBottom fillWithBlendMode:kCGBlendModeNormal alpha:self.bottomAlpha];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (self.topGradient != nil) {
        CGContextSaveGState(ctx);
        CGContextAddPath(ctx, [fillTop CGPath]);
        CGContextClip(ctx);
        CGContextDrawLinearGradient(ctx, self.topGradient, CGPointZero, CGPointMake(0, CGRectGetMaxY(fillTop.bounds)), 0);
        CGContextRestoreGState(ctx);
    }

    if (self.bottomGradient != nil) {
        CGContextSaveGState(ctx);
        CGContextAddPath(ctx, [fillBottom CGPath]);
        CGContextClip(ctx);
        CGContextDrawLinearGradient(ctx, self.bottomGradient, CGPointZero, CGPointMake(0, CGRectGetMaxY(fillBottom.bounds)), 0);
        CGContextRestoreGState(ctx);
    }

    UIImage *lineAndFillImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    // Image context ends here
    
    CALayer *lineAndFillLayer = [CALayer new];
    lineAndFillLayer.contents = (id)lineAndFillImage.CGImage;
    lineAndFillLayer.frame = self.bounds;
    [self.layer addSublayer:lineAndFillLayer];
    
    //------ Draw The Head Point ------//
    
    CALayer *headPointLayer;
    if (self.points.count > 0) {
        CAShapeLayer *headPointOuterLayer = [CAShapeLayer new];
        CAShapeLayer *headPointInerLayer = [CAShapeLayer new];

        CGRect headPointLayerBounds = CGRectMake(0, 0, 2 * self.headPointOuterRadius, 2 * self.headPointOuterRadius);
        
        headPointOuterLayer.frame = headPointLayerBounds;
        headPointOuterLayer.path = [UIBezierPath bezierPathWithOvalInRect:headPointLayerBounds].CGPath;
        headPointOuterLayer.fillColor = self.headPointOuterColor.CGColor;
        
        if (self.headPointIsAnimating) {
            CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            scaleAnimation.duration = 0.7;
            scaleAnimation.repeatCount = HUGE_VALF;
            scaleAnimation.autoreverses = YES;
            scaleAnimation.fromValue = @(1.0);
            scaleAnimation.toValue = @(self.headPointInnerRadius / self.headPointOuterRadius);
            [headPointOuterLayer addAnimation:scaleAnimation forKey:@"scaleAnimation"];
        }
        
        headPointInerLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.headPointOuterRadius, self.headPointOuterRadius) radius:self.headPointInnerRadius startAngle:0 endAngle:2 * M_PI clockwise:YES].CGPath;
        headPointInerLayer.fillColor = self.headPointInnerColor.CGColor;
        
        headPointLayer = [CALayer new];
        headPointLayer.bounds = headPointLayerBounds;
        headPointLayer.position = [(NSValue *)self.points.lastObject CGPointValue];
        [headPointLayer addSublayer:headPointOuterLayer];
        [headPointLayer addSublayer:headPointInerLayer];
        
        headPointLayer.shadowColor = self.headPointShadowColor.CGColor;
        headPointLayer.shadowOffset = self.headPointShadowOffset;
        headPointLayer.shadowRadius = self.headPointShadowRadius;
        headPointLayer.shadowOpacity = self.headPointShadowOpacity;
        
        [self.layer addSublayer:headPointLayer];
    }

    //----------------------------//
    //------ Animate Drawing -----//
    //----------------------------//
    if (self.enableRefrenceLines == YES) {
        CAShapeLayer *verticalReferenceLinesPathLayer = [CAShapeLayer layer];
        verticalReferenceLinesPathLayer.frame = self.bounds;
        verticalReferenceLinesPathLayer.path = verticalReferenceLinesPath.CGPath;
        verticalReferenceLinesPathLayer.opacity = self.lineAlpha == 0 ? 0.1 : self.lineAlpha/2;
        verticalReferenceLinesPathLayer.fillColor = nil;
        verticalReferenceLinesPathLayer.lineWidth = self.referenceLineWidth/2;
        
        if (self.lineDashPatternForReferenceYAxisLines) {
            verticalReferenceLinesPathLayer.lineDashPattern = self.lineDashPatternForReferenceYAxisLines;
        }

        if (self.refrenceLineColor) {
            verticalReferenceLinesPathLayer.strokeColor = self.refrenceLineColor.CGColor;
        } else {
            verticalReferenceLinesPathLayer.strokeColor = self.color.CGColor;
        }

        if (self.animationTime > 0)
            [self animateForLayer:verticalReferenceLinesPathLayer withAnimationType:self.animationType isAnimatingReferenceLine:YES];
        [self.layer addSublayer:verticalReferenceLinesPathLayer];


        CAShapeLayer *horizontalReferenceLinesPathLayer = [CAShapeLayer layer];
        horizontalReferenceLinesPathLayer.frame = self.bounds;
        horizontalReferenceLinesPathLayer.path = horizontalReferenceLinesPath.CGPath;
        horizontalReferenceLinesPathLayer.opacity = self.lineAlpha == 0 ? 0.1 : self.lineAlpha/2;
        horizontalReferenceLinesPathLayer.fillColor = nil;
        horizontalReferenceLinesPathLayer.lineWidth = self.referenceLineWidth/2;
        horizontalReferenceLinesPathLayer.zPosition = -1;
        if(self.lineDashPatternForReferenceXAxisLines) {
            horizontalReferenceLinesPathLayer.lineDashPattern = self.lineDashPatternForReferenceXAxisLines;
        }

        if (self.refrenceLineColor) {
            horizontalReferenceLinesPathLayer.strokeColor = self.refrenceLineColor.CGColor;
        } else {
            horizontalReferenceLinesPathLayer.strokeColor = self.color.CGColor;
        }

        if (self.animationTime > 0)
            [self animateForLayer:horizontalReferenceLinesPathLayer withAnimationType:self.animationType isAnimatingReferenceLine:YES];
        [self.layer addSublayer:horizontalReferenceLinesPathLayer];
    }

    CAShapeLayer *referenceLinesPathLayer = [CAShapeLayer layer];
    referenceLinesPathLayer.frame = self.bounds;
    referenceLinesPathLayer.path = referenceFramePath.CGPath;
    referenceLinesPathLayer.opacity = self.lineAlpha == 0 ? 0.1 : self.lineAlpha/2;
    referenceLinesPathLayer.fillColor = nil;
    referenceLinesPathLayer.lineWidth = self.referenceLineWidth/2;

    if (self.refrenceLineColor) referenceLinesPathLayer.strokeColor = self.refrenceLineColor.CGColor;
    else referenceLinesPathLayer.strokeColor = self.color.CGColor;

    if (self.animationTime > 0)
        [self animateForLayer:referenceLinesPathLayer withAnimationType:self.animationType isAnimatingReferenceLine:YES];
    [self.layer addSublayer:referenceLinesPathLayer];

    if (self.disableMainLine == NO) {
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.frame = self.bounds;
        pathLayer.path = line.CGPath;
        pathLayer.strokeColor = self.color.CGColor;
        pathLayer.fillColor = nil;
        pathLayer.opacity = self.lineAlpha;
        pathLayer.lineWidth = self.lineWidth;
        pathLayer.lineJoin = kCALineJoinBevel;
        pathLayer.lineCap = kCALineCapRound;
        
        CALayer *addingPathLayer;
        if (self.lineGradient){
            addingPathLayer = [self backgroundGradientLayerForLayer:pathLayer];
        } else {
            addingPathLayer = pathLayer;
        }
        [lineAndFillLayer addSublayer:addingPathLayer];
    }
    
    if (self.animationTime > 0) {
        CALayer *maskLayer = [CALayer new];
        maskLayer.backgroundColor = [UIColor whiteColor].CGColor;
        
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.duration = self.animationTime;
        boundsAnimation.fromValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 0, self.bounds.size.height)];
        boundsAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        [maskLayer addAnimation:boundsAnimation forKey:@"bounds"];
        
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.duration = self.animationTime;
        positionAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, self.bounds.size.height / 2)];
        positionAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2)];
        [maskLayer addAnimation:positionAnimation forKey:@"position"];
        
        maskLayer.frame = self.bounds;
        
        lineAndFillLayer.mask = maskLayer;
    }
    
    if (self.animationTime > 0 && self.headPointOuterRadius > 0 && self.points.count > 0) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        animation.path = line.CGPath;
    
        NSMutableArray *keyTimes = [NSMutableArray new];
        CGFloat minX = 0;
        CGFloat maxX = self.bounds.size.width;
        
        CGFloat time0 = ([self.arrayOfXValues[0] CGFloatValue] - minX) / (maxX - minX);
        [keyTimes addObject:@(time0)];
        for (int i = 0; i < self.arrayOfXValues.count - 1; ++i) {
            if (maxX - minX == 0) {
                [keyTimes addObject:@1];
                [keyTimes addObject:@1];
            } else {
                CGFloat time1 = ([self.arrayOfXValues[i + 1] CGFloatValue] - minX) / (maxX - minX);
                [keyTimes addObject:@(time1)];
            }
        }
        animation.keyTimes = keyTimes;
        
        animation.duration = self.animationTime;
        [headPointLayer addAnimation:animation forKey:@"position"];
    }

    if (self.averageLine.enableAverageLine == YES) {
        CAShapeLayer *averageLinePathLayer = [CAShapeLayer layer];
        averageLinePathLayer.frame = self.bounds;
        averageLinePathLayer.path = averageLinePath.CGPath;
        averageLinePathLayer.opacity = self.averageLine.alpha;
        averageLinePathLayer.fillColor = nil;
        averageLinePathLayer.lineWidth = self.averageLine.width;

        if (self.averageLine.dashPattern) averageLinePathLayer.lineDashPattern = self.averageLine.dashPattern;

        if (self.averageLine.color) averageLinePathLayer.strokeColor = self.averageLine.color.CGColor;
        else averageLinePathLayer.strokeColor = self.color.CGColor;

        if (self.animationTime > 0)
            [self animateForLayer:averageLinePathLayer withAnimationType:self.animationType isAnimatingReferenceLine:NO];
        [self.layer addSublayer:averageLinePathLayer];
    }
}

- (UIBezierPath *)topFillPath {
    CGPoint topPointZero = CGPointMake([self.arrayOfXValues.firstObject CGFloatValue], 0);
    CGPoint topPointFull = CGPointMake([self.arrayOfXValues.lastObject CGFloatValue], 0);
    
    UIBezierPath *path;
    if (self.bezierCurveIsEnabled) {
        path = [BEMLine quadCurvedPathWithPoints:self.points];
    } else {
        path = [BEMLine linesToPoints:self.points];
    }
    [path addLineToPoint:topPointFull];
    [path addLineToPoint:topPointZero];
    [path closePath];
    
    return path;
}

- (UIBezierPath *)bottomFillPath {
    NSMutableArray *bottomPoints;
    if (self.bottomOffset == 0) {
        bottomPoints = [NSMutableArray arrayWithArray:self.points];
    } else {
        bottomPoints = [NSMutableArray new];
        for (NSValue *point in self.points) {
            NSValue *offsetPoint = [NSValue valueWithCGPoint:CGPointMake(point.CGPointValue.x, point.CGPointValue.y + self.bottomOffset)];
            [bottomPoints addObject:offsetPoint];
        }
    }

    CGPoint bottomPointZero = CGPointMake([self.arrayOfXValues.firstObject CGFloatValue], self.frame.size.height);
    CGPoint bottomPointFull = CGPointMake([self.arrayOfXValues.lastObject CGFloatValue], self.frame.size.height);

    UIBezierPath *path;
    if (self.bezierCurveIsEnabled) {
        path = [BEMLine quadCurvedPathWithPoints:bottomPoints];
    } else {
        path = [BEMLine linesToPoints:bottomPoints];
    }
    [path addLineToPoint:bottomPointFull];
    [path addLineToPoint:bottomPointZero];
    [path closePath];
    
    return path;
}

+ (UIBezierPath *)linesToPoints:(NSArray *)points {
    UIBezierPath *path = [UIBezierPath bezierPath];
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];

    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
    }
    return path;
}

+ (UIBezierPath *)quadCurvedPathWithPoints:(NSArray *)points {
    NSMutableArray *twoMorePoints = [points mutableCopy];
    
    NSValue *firstPoint = points[0];
    NSValue *lastPoint = points[points.count - 1];
    
    [twoMorePoints insertObject:firstPoint atIndex:0];
    [twoMorePoints addObject:lastPoint];
    
    return [UIBezierPath interpolateCGPointsWithCatmullRom:twoMorePoints closed:NO alpha:0.5];
}

- (void)animateForLayer:(CAShapeLayer *)shapeLayer withAnimationType:(BEMLineAnimation)animationType isAnimatingReferenceLine:(BOOL)shouldHalfOpacity {
    if (animationType == BEMLineAnimationNone) return;
    else if (animationType == BEMLineAnimationFade) {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        pathAnimation.duration = self.animationTime;
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        if (shouldHalfOpacity == YES) pathAnimation.toValue = [NSNumber numberWithFloat:self.lineAlpha == 0 ? 0.1 : self.lineAlpha/2];
        else pathAnimation.toValue = [NSNumber numberWithFloat:self.lineAlpha];
        [shapeLayer addAnimation:pathAnimation forKey:@"opacity"];

        return;
    } else if (animationType == BEMLineAnimationExpand) {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
        pathAnimation.duration = self.animationTime;
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue = [NSNumber numberWithFloat:shapeLayer.lineWidth];
        [shapeLayer addAnimation:pathAnimation forKey:@"lineWidth"];

        return;
    } else {
        return;
    }
}

- (CALayer *)backgroundGradientLayerForLayer:(CAShapeLayer *)shapeLayer {
    UIGraphicsBeginImageContext(self.bounds.size);
    CGContextRef imageCtx = UIGraphicsGetCurrentContext();
    CGPoint start, end;
    if (self.lineGradientDirection == BEMLineGradientDirectionHorizontal) {
        start = CGPointMake(0, CGRectGetMidY(shapeLayer.bounds));
        end = CGPointMake(CGRectGetMaxX(shapeLayer.bounds), CGRectGetMidY(shapeLayer.bounds));
    } else {
        start = CGPointMake(CGRectGetMidX(shapeLayer.bounds), 0);
        end = CGPointMake(CGRectGetMidX(shapeLayer.bounds), CGRectGetMaxY(shapeLayer.bounds));
    }

    CGContextDrawLinearGradient(imageCtx, self.lineGradient, start, end, 0);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CALayer *gradientLayer = [CALayer layer];
    gradientLayer.frame = self.bounds;
    gradientLayer.contents = (id)image.CGImage;
    gradientLayer.mask = shapeLayer;
    return gradientLayer;
}

@end
