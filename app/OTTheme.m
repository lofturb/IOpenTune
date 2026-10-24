//
//  OTTheme.m
//  OpenTune 9
//

#import "OTTheme.h"
#import <math.h>

static NSUInteger gAccentHex = 0xED5564;
static BOOL gPureBlack = NO;
static UIColor *gArtworkColor = nil;

static void OTDrawLine(CGContextRef ctx, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2)
{
    CGContextMoveToPoint(ctx, x1, y1);
    CGContextAddLineToPoint(ctx, x2, y2);
    CGContextStrokePath(ctx);
}

@interface OTTheme ()
+ (UIColor *)shiftColor:(UIColor *)color brightness:(CGFloat)brightness saturation:(CGFloat)saturationScale;
+ (UIColor *)baseAccent;
+ (CGGradientRef)gradientFrom:(UIColor *)from to:(UIColor *)to;
@end

@implementation OTTheme

#pragma mark - Color

+ (UIColor *)colorWithHex:(NSUInteger)hex
{
    return [self colorWithHex:hex alpha:1.0];
}

+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha
{
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:alpha];
}

+ (UIColor *)shiftColor:(UIColor *)color brightness:(CGFloat)brightness saturation:(CGFloat)saturationScale
{
    CGFloat h = 0, s = 0, b = 0, a = 0;
    if (![color getHue:&h saturation:&s brightness:&b alpha:&a]) {
        return color;
    }
    s = MAX(0.0, MIN(1.0, s * saturationScale));
    b = MAX(0.0, MIN(1.0, brightness));
    return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
}

+ (UIColor *)baseAccent
{
    if (gArtworkColor) {
        return gArtworkColor;
    }
    return [self colorWithHex:gAccentHex];
}

+ (void)setAccentHex:(NSUInteger)hex
{
    gAccentHex = hex;
    gArtworkColor = nil;
}

+ (NSUInteger)accentHex
{
    return gAccentHex;
}

+ (void)applyArtworkColor:(UIColor *)color
{
    gArtworkColor = color;
}

+ (void)clearArtworkColor
{
    gArtworkColor = nil;
}

+ (void)setPureBlack:(BOOL)pureBlack
{
    gPureBlack = pureBlack;
}

+ (BOOL)pureBlack
{
    return gPureBlack;
}

+ (UIColor *)background
{
    return gPureBlack ? [UIColor blackColor] : [self colorWithHex:0x141218];
}

+ (UIColor *)surface
{
    return gPureBlack ? [self colorWithHex:0x0A0A0C] : [self colorWithHex:0x1D1B20];
}

+ (UIColor *)surfaceContainer
{
    return gPureBlack ? [self colorWithHex:0x111114] : [self colorWithHex:0x211F26];
}

+ (UIColor *)surfaceHigh
{
    return gPureBlack ? [self colorWithHex:0x17171A] : [self colorWithHex:0x2B2930];
}

+ (UIColor *)surfaceHighest
{
    return gPureBlack ? [self colorWithHex:0x1E1E21] : [self colorWithHex:0x36343B];
}

+ (UIColor *)navBackground
{
    return [self surfaceContainer];
}

+ (UIColor *)text
{
    return [self colorWithHex:0xE6E0E9];
}

+ (UIColor *)secondaryText
{
    return [self colorWithHex:0xCAC4D0];
}

+ (UIColor *)separator
{
    return [self colorWithHex:0x49454F];
}

+ (UIColor *)outline
{
    return [self colorWithHex:0x938F99];
}

+ (UIColor *)primary
{
    return [self shiftColor:[self baseAccent] brightness:0.94 saturation:0.42];
}

+ (UIColor *)onPrimary
{
    return [self shiftColor:[self baseAccent] brightness:0.34 saturation:0.85];
}

+ (UIColor *)primaryContainer
{
    return [self shiftColor:[self baseAccent] brightness:0.52 saturation:0.62];
}

+ (UIColor *)onPrimaryContainer
{
    return [self shiftColor:[self baseAccent] brightness:0.96 saturation:0.30];
}

+ (UIColor *)secondary
{
    return [self shiftColor:[self baseAccent] brightness:0.88 saturation:0.24];
}

+ (UIColor *)secondaryContainer
{
    return [self shiftColor:[self baseAccent] brightness:0.40 saturation:0.36];
}

+ (UIColor *)onSecondaryContainer
{
    return [self shiftColor:[self baseAccent] brightness:0.95 saturation:0.24];
}

+ (UIColor *)tertiary
{
    CGFloat h = 0, s = 0, b = 0, a = 0;
    [[self baseAccent] getHue:&h saturation:&s brightness:&b alpha:&a];
    h = fmod(h + 0.12, 1.0);
    return [UIColor colorWithHue:h saturation:0.45 brightness:0.90 alpha:1.0];
}

+ (UIColor *)error
{
    return [self colorWithHex:0xFFB4AB];
}

#pragma mark - Typography

+ (UIFont *)font:(CGFloat)size weight:(CGFloat)weight
{
    return [UIFont systemFontOfSize:size weight:weight];
}

+ (UIFont *)displaySmall { return [self font:34.0 weight:UIFontWeightRegular]; }
+ (UIFont *)headlineSmall { return [self font:24.0 weight:UIFontWeightRegular]; }
+ (UIFont *)headlineMedium { return [self font:28.0 weight:UIFontWeightRegular]; }
+ (UIFont *)titleLarge { return [self font:22.0 weight:UIFontWeightMedium]; }
+ (UIFont *)titleMedium { return [self font:16.0 weight:UIFontWeightMedium]; }
+ (UIFont *)titleSmall { return [self font:14.0 weight:UIFontWeightMedium]; }
+ (UIFont *)bodyLarge { return [self font:16.0 weight:UIFontWeightRegular]; }
+ (UIFont *)bodyMedium { return [self font:14.0 weight:UIFontWeightRegular]; }
+ (UIFont *)bodySmall { return [self font:12.0 weight:UIFontWeightRegular]; }
+ (UIFont *)labelLarge { return [self font:14.0 weight:UIFontWeightMedium]; }
+ (UIFont *)labelMedium { return [self font:12.0 weight:UIFontWeightMedium]; }
+ (UIFont *)labelSmall { return [self font:11.0 weight:UIFontWeightMedium]; }

#pragma mark - Icons

+ (UIImage *)icon:(OTIcon)icon size:(CGFloat)size
{
    return [self icon:icon size:size weight:1.9];
}

+ (UIImage *)icon:(OTIcon)icon size:(CGFloat)size weight:(CGFloat)weight
{
    if (size <= 0) {
        size = 24.0;
    }
    CGFloat scale = size / 24.0;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(ctx, scale, scale);
    CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(ctx, weight);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    switch (icon) {
        case OTIconHome: {
            CGContextMoveToPoint(ctx, 3.0, 10.2);
            CGContextAddLineToPoint(ctx, 12.0, 3.2);
            CGContextAddLineToPoint(ctx, 21.0, 10.2);
            CGContextAddLineToPoint(ctx, 21.0, 20.5);
            CGContextAddLineToPoint(ctx, 14.2, 20.5);
            CGContextAddLineToPoint(ctx, 14.2, 14.6);
            CGContextAddLineToPoint(ctx, 9.8, 14.6);
            CGContextAddLineToPoint(ctx, 9.8, 20.5);
            CGContextAddLineToPoint(ctx, 3.0, 20.5);
            CGContextClosePath(ctx);
            CGContextStrokePath(ctx);
            break;
        }
        case OTIconSearch: {
            CGContextStrokeEllipseInRect(ctx, CGRectMake(3.4, 3.4, 12.6, 12.6));
            OTDrawLine(ctx, 15.0, 15.0, 20.6, 20.6);
            break;
        }
        case OTIconLibrary: {
            UIBezierPath *p1 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.5, 4.0, 3.2, 16.0) cornerRadius:1.4];
            [p1 fill];
            UIBezierPath *p2 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(9.4, 4.0, 3.2, 16.0) cornerRadius:1.4];
            [p2 fill];
            UIBezierPath *p3 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(15.3, 7.0, 3.2, 13.0) cornerRadius:1.4];
            [p3 fill];
            break;
        }
        case OTIconMood: {
            CGContextStrokeEllipseInRect(ctx, CGRectMake(2.8, 2.8, 18.4, 18.4));
            CGContextFillEllipseInRect(ctx, CGRectMake(8.1, 9.0, 2.1, 2.6));
            CGContextFillEllipseInRect(ctx, CGRectMake(13.8, 9.0, 2.1, 2.6));
            UIBezierPath *smile = [UIBezierPath bezierPathWithArcCenter:CGPointMake(12.0, 12.0)
                                                                radius:5.0
                                                            startAngle:0.42
                                                              endAngle:M_PI - 0.42
                                                             clockwise:YES];
            [smile stroke];
            break;
        }
        case OTIconSettings: {
            UIBezierPath *gear = [UIBezierPath bezierPath];
            CGFloat outer = 9.4, inner = 7.3;
            for (int i = 0; i < 16; i++) {
                CGFloat angle = (M_PI * 2.0 / 16.0) * i - M_PI / 2.0;
                CGFloat r = (i % 2 == 0) ? outer : inner;
                CGPoint pt = CGPointMake(12.0 + cosf(angle) * r, 12.0 + sinf(angle) * r);
                if (i == 0) [gear moveToPoint:pt]; else [gear addLineToPoint:pt];
            }
            [gear closePath];
            [gear appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(9.0, 9.0, 6.0, 6.0)]];
            [gear setUsesEvenOddFillRule:YES];
            CGContextAddPath(ctx, gear.CGPath);
            CGContextEOFillPath(ctx);
            break;
        }
        case OTIconMoreVert: {
            CGContextFillEllipseInRect(ctx, CGRectMake(10.2, 3.8, 3.6, 3.6));
            CGContextFillEllipseInRect(ctx, CGRectMake(10.2, 10.2, 3.6, 3.6));
            CGContextFillEllipseInRect(ctx, CGRectMake(10.2, 16.6, 3.6, 3.6));
            break;
        }
        case OTIconMoreHoriz: {
            CGContextFillEllipseInRect(ctx, CGRectMake(3.8, 10.2, 3.6, 3.6));
            CGContextFillEllipseInRect(ctx, CGRectMake(10.2, 10.2, 3.6, 3.6));
            CGContextFillEllipseInRect(ctx, CGRectMake(16.6, 10.2, 3.6, 3.6));
            break;
        }
        case OTIconPlay: {
            CGContextMoveToPoint(ctx, 7.6, 4.8);
            CGContextAddLineToPoint(ctx, 19.4, 12.0);
            CGContextAddLineToPoint(ctx, 7.6, 19.2);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            break;
        }
        case OTIconPause: {
            UIBezierPath *a = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(6.6, 4.8, 4.0, 14.4) cornerRadius:1.3];
            [a fill];
            UIBezierPath *b = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(13.4, 4.8, 4.0, 14.4) cornerRadius:1.3];
            [b fill];
            break;
        }
        case OTIconNext: {
            CGContextMoveToPoint(ctx, 5.8, 5.2);
            CGContextAddLineToPoint(ctx, 15.8, 12.0);
            CGContextAddLineToPoint(ctx, 5.8, 18.8);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            UIBezierPath *bar = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(16.6, 5.0, 2.6, 14.0) cornerRadius:1.1];
            [bar fill];
            break;
        }
        case OTIconPrev: {
            UIBezierPath *bar = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(4.8, 5.0, 2.6, 14.0) cornerRadius:1.1];
            [bar fill];
            CGContextMoveToPoint(ctx, 18.2, 5.2);
            CGContextAddLineToPoint(ctx, 8.2, 12.0);
            CGContextAddLineToPoint(ctx, 18.2, 18.8);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            break;
        }
        case OTIconShuffle: {
            CGContextMoveToPoint(ctx, 3.0, 7.2);
            CGContextAddLineToPoint(ctx, 6.4, 7.2);
            CGContextAddCurveToPoint(ctx, 9.2, 7.2, 10.4, 9.0, 12.0, 11.2);
            CGContextAddCurveToPoint(ctx, 13.6, 13.4, 15.0, 16.0, 17.6, 16.0);
            CGContextAddLineToPoint(ctx, 20.6, 16.0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 18.0, 13.4, 20.6, 16.0);
            OTDrawLine(ctx, 18.0, 18.6, 20.6, 16.0);
            CGContextMoveToPoint(ctx, 3.0, 16.0);
            CGContextAddLineToPoint(ctx, 6.4, 16.0);
            CGContextAddCurveToPoint(ctx, 9.2, 16.0, 10.4, 14.2, 12.0, 12.0);
            CGContextAddCurveToPoint(ctx, 13.6, 9.8, 15.0, 7.2, 17.6, 7.2);
            CGContextAddLineToPoint(ctx, 20.6, 7.2);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 18.0, 4.6, 20.6, 7.2);
            OTDrawLine(ctx, 18.0, 9.8, 20.6, 7.2);
            break;
        }
        case OTIconRepeat: {
            CGContextMoveToPoint(ctx, 5.0, 12.0);
            CGContextAddLineToPoint(ctx, 5.0, 9.2);
            CGContextAddQuadCurveToPoint(ctx, 5.0, 6.6, 7.6, 6.6);
            CGContextAddLineToPoint(ctx, 16.4, 6.6);
            CGContextAddQuadCurveToPoint(ctx, 19.0, 6.6, 19.0, 9.2);
            CGContextAddLineToPoint(ctx, 19.0, 12.0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 16.4, 4.2, 19.0, 6.6);
            OTDrawLine(ctx, 21.6, 4.2, 19.0, 6.6);
            CGContextMoveToPoint(ctx, 19.0, 12.0);
            CGContextAddLineToPoint(ctx, 19.0, 14.8);
            CGContextAddQuadCurveToPoint(ctx, 19.0, 17.4, 16.4, 17.4);
            CGContextAddLineToPoint(ctx, 7.6, 17.4);
            CGContextAddQuadCurveToPoint(ctx, 5.0, 17.4, 5.0, 14.8);
            CGContextAddLineToPoint(ctx, 5.0, 12.0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 7.6, 19.8, 5.0, 17.4);
            OTDrawLine(ctx, 2.4, 19.8, 5.0, 17.4);
            break;
        }
        case OTIconRepeatOne: {
            CGContextMoveToPoint(ctx, 5.0, 12.0);
            CGContextAddLineToPoint(ctx, 5.0, 9.2);
            CGContextAddQuadCurveToPoint(ctx, 5.0, 6.6, 7.6, 6.6);
            CGContextAddLineToPoint(ctx, 16.4, 6.6);
            CGContextAddQuadCurveToPoint(ctx, 19.0, 6.6, 19.0, 9.2);
            CGContextAddLineToPoint(ctx, 19.0, 12.0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 16.4, 4.2, 19.0, 6.6);
            OTDrawLine(ctx, 21.6, 4.2, 19.0, 6.6);
            CGContextMoveToPoint(ctx, 19.0, 12.0);
            CGContextAddLineToPoint(ctx, 19.0, 14.8);
            CGContextAddQuadCurveToPoint(ctx, 19.0, 17.4, 16.4, 17.4);
            CGContextAddLineToPoint(ctx, 7.6, 17.4);
            CGContextAddQuadCurveToPoint(ctx, 5.0, 17.4, 5.0, 14.8);
            CGContextAddLineToPoint(ctx, 5.0, 12.0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 7.6, 19.8, 5.0, 17.4);
            OTDrawLine(ctx, 2.4, 19.8, 5.0, 17.4);
            OTDrawLine(ctx, 12.0, 10.4, 12.0, 14.2);
            OTDrawLine(ctx, 12.0, 10.4, 10.4, 11.6);
            break;
        }
        case OTIconHeart:
        case OTIconHeartFill: {
            UIBezierPath *heart = [UIBezierPath bezierPath];
            [heart moveToPoint:CGPointMake(12.0, 20.4)];
            [heart addCurveToPoint:CGPointMake(3.2, 8.9)
                     controlPoint1:CGPointMake(9.6, 17.6)
                     controlPoint2:CGPointMake(3.2, 13.6)];
            [heart addCurveToPoint:CGPointMake(8.2, 3.6)
                     controlPoint1:CGPointMake(3.2, 5.8)
                     controlPoint2:CGPointMake(5.4, 3.6)];
            [heart addCurveToPoint:CGPointMake(12.0, 6.0)
                     controlPoint1:CGPointMake(10.0, 3.6)
                     controlPoint2:CGPointMake(11.2, 4.7)];
            [heart addCurveToPoint:CGPointMake(15.8, 3.6)
                     controlPoint1:CGPointMake(12.8, 4.7)
                     controlPoint2:CGPointMake(14.0, 3.6)];
            [heart addCurveToPoint:CGPointMake(20.8, 8.9)
                     controlPoint1:CGPointMake(18.6, 3.6)
                     controlPoint2:CGPointMake(20.8, 5.8)];
            [heart addCurveToPoint:CGPointMake(12.0, 20.4)
                     controlPoint1:CGPointMake(20.8, 13.6)
                     controlPoint2:CGPointMake(14.4, 17.6)];
            [heart closePath];
            if (icon == OTIconHeartFill) {
                [heart fill];
            } else {
                [heart stroke];
            }
            break;
        }
        case OTIconDownload: {
            OTDrawLine(ctx, 12.0, 3.2, 12.0, 15.2);
            OTDrawLine(ctx, 7.2, 10.4, 12.0, 15.2);
            OTDrawLine(ctx, 16.8, 10.4, 12.0, 15.2);
            CGContextMoveToPoint(ctx, 4.0, 16.6);
            CGContextAddLineToPoint(ctx, 4.0, 20.0);
            CGContextAddQuadCurveToPoint(ctx, 4.0, 21.0, 5.0, 21.0);
            CGContextAddLineToPoint(ctx, 19.0, 21.0);
            CGContextAddQuadCurveToPoint(ctx, 20.0, 21.0, 20.0, 20.0);
            CGContextAddLineToPoint(ctx, 20.0, 16.6);
            CGContextStrokePath(ctx);
            break;
        }
        case OTIconDone: {
            OTDrawLine(ctx, 4.4, 12.4, 9.4, 17.4);
            OTDrawLine(ctx, 9.4, 17.4, 19.6, 6.6);
            break;
        }
        case OTIconQueue: {
            OTDrawLine(ctx, 3.0, 6.6, 13.4, 6.6);
            OTDrawLine(ctx, 3.0, 11.8, 13.4, 11.8);
            OTDrawLine(ctx, 3.0, 17.0, 9.4, 17.0);
            CGContextMoveToPoint(ctx, 15.0, 9.4);
            CGContextAddLineToPoint(ctx, 21.4, 14.0);
            CGContextAddLineToPoint(ctx, 15.0, 18.6);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            break;
        }
        case OTIconLyrics: {
            UIBezierPath *bubble = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.0, 3.6, 18.0, 13.4) cornerRadius:3.6];
            [bubble stroke];
            CGContextMoveToPoint(ctx, 8.0, 17.0);
            CGContextAddLineToPoint(ctx, 8.0, 21.2);
            CGContextAddLineToPoint(ctx, 12.4, 17.0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 6.6, 8.0, 17.4, 8.0);
            OTDrawLine(ctx, 6.6, 12.2, 13.6, 12.2);
            break;
        }
        case OTIconClose: {
            OTDrawLine(ctx, 6.0, 6.0, 18.0, 18.0);
            OTDrawLine(ctx, 18.0, 6.0, 6.0, 18.0);
            break;
        }
        case OTIconBack: {
            OTDrawLine(ctx, 15.0, 4.4, 7.4, 12.0);
            OTDrawLine(ctx, 7.4, 12.0, 15.0, 19.6);
            break;
        }
        case OTIconChevronRight: {
            OTDrawLine(ctx, 9.0, 4.6, 16.4, 12.0);
            OTDrawLine(ctx, 16.4, 12.0, 9.0, 19.4);
            break;
        }
        case OTIconChevronDown: {
            OTDrawLine(ctx, 4.6, 9.0, 12.0, 16.4);
            OTDrawLine(ctx, 12.0, 16.4, 19.4, 9.0);
            break;
        }
        case OTIconPlus: {
            OTDrawLine(ctx, 12.0, 4.0, 12.0, 20.0);
            OTDrawLine(ctx, 4.0, 12.0, 20.0, 12.0);
            break;
        }
        case OTIconTrash: {
            OTDrawLine(ctx, 4.0, 6.8, 20.0, 6.8);
            OTDrawLine(ctx, 9.0, 6.8, 9.0, 3.8);
            OTDrawLine(ctx, 9.0, 3.8, 15.0, 3.8);
            OTDrawLine(ctx, 15.0, 3.8, 15.0, 6.8);
            CGContextMoveToPoint(ctx, 6.0, 6.8);
            CGContextAddLineToPoint(ctx, 7.0, 20.4);
            CGContextAddLineToPoint(ctx, 17.0, 20.4);
            CGContextAddLineToPoint(ctx, 18.0, 6.8);
            CGContextStrokePath(ctx);
            break;
        }
        case OTIconClock: {
            CGContextStrokeEllipseInRect(ctx, CGRectMake(3.0, 3.0, 18.0, 18.0));
            OTDrawLine(ctx, 12.0, 7.0, 12.0, 12.2);
            OTDrawLine(ctx, 12.0, 12.2, 16.2, 14.6);
            break;
        }
        case OTIconCheck: {
            OTDrawLine(ctx, 4.4, 12.4, 9.4, 17.4);
            OTDrawLine(ctx, 9.4, 17.4, 19.6, 6.6);
            break;
        }
        case OTIconAlbum: {
            CGContextStrokeEllipseInRect(ctx, CGRectMake(2.6, 2.6, 18.8, 18.8));
            CGContextFillEllipseInRect(ctx, CGRectMake(9.6, 9.6, 4.8, 4.8));
            break;
        }
        case OTIconArtist: {
            CGContextStrokeEllipseInRect(ctx, CGRectMake(8.4, 3.0, 7.2, 7.2));
            CGContextMoveToPoint(ctx, 4.0, 20.6);
            CGContextAddQuadCurveToPoint(ctx, 12.0, 12.2, 20.0, 20.6);
            CGContextStrokePath(ctx);
            break;
        }
        case OTIconPlaylist: {
            OTDrawLine(ctx, 3.0, 5.0, 21.0, 5.0);
            OTDrawLine(ctx, 3.0, 10.0, 21.0, 10.0);
            OTDrawLine(ctx, 3.0, 15.0, 13.0, 15.0);
            CGContextFillEllipseInRect(ctx, CGRectMake(13.4, 16.4, 5.2, 4.4));
            OTDrawLine(ctx, 18.4, 18.6, 18.4, 8.6);
            OTDrawLine(ctx, 18.4, 8.6, 21.6, 9.6);
            break;
        }
        case OTIconVideo: {
            UIBezierPath *rect = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2.6, 5.6, 18.8, 12.8) cornerRadius:3.0];
            [rect stroke];
            CGContextMoveToPoint(ctx, 10.2, 9.0);
            CGContextAddLineToPoint(ctx, 15.6, 12.0);
            CGContextAddLineToPoint(ctx, 10.2, 15.0);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            break;
        }
        case OTIconRefresh: {
            CGContextMoveToPoint(ctx, 20.0, 12.0);
            CGContextAddArc(ctx, 12.0, 12.0, 8.0, 0.0, -M_PI * 1.45, 1);
            CGContextAddLineToPoint(ctx, 12.0, 12.0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 20.0, 4.2, 20.0, 12.0);
            OTDrawLine(ctx, 20.0, 4.2, 16.2, 8.0);
            break;
        }
        case OTIconUser: {
            CGContextStrokeEllipseInRect(ctx, CGRectMake(8.0, 2.8, 8.0, 8.0));
            CGContextMoveToPoint(ctx, 3.6, 21.0);
            CGContextAddQuadCurveToPoint(ctx, 12.0, 12.0, 20.4, 21.0);
            CGContextStrokePath(ctx);
            break;
        }
        case OTIconStats: {
            UIBezierPath *b1 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.4, 13.0, 3.4, 8.0) cornerRadius:1.0];
            [b1 fill];
            UIBezierPath *b2 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(8.9, 8.4, 3.4, 12.6) cornerRadius:1.0];
            [b2 fill];
            UIBezierPath *b3 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(14.4, 11.0, 3.4, 10.0) cornerRadius:1.0];
            [b3 fill];
            UIBezierPath *b4 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(19.9, 3.6, 1.6, 17.4) cornerRadius:0.8];
            [b4 fill];
            break;
        }
        case OTIconSleep: {
            UIBezierPath *moon = [UIBezierPath bezierPath];
            [moon moveToPoint:CGPointMake(20.4, 14.4)];
            [moon addCurveToPoint:CGPointMake(9.6, 3.6)
                    controlPoint1:CGPointMake(20.4, 8.4)
                    controlPoint2:CGPointMake(15.6, 3.6)];
            [moon addCurveToPoint:CGPointMake(20.4, 14.4)
                    controlPoint1:CGPointMake(9.6, 11.4)
                    controlPoint2:CGPointMake(14.4, 16.2)];
            [moon closePath];
            [moon fill];
            break;
        }
        case OTIconSpeed: {
            CGContextMoveToPoint(ctx, 3.4, 15.4);
            CGContextAddArc(ctx, 12.0, 15.6, 8.6, M_PI, 0.0, 0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 12.0, 15.4, 16.6, 9.4);
            CGContextFillEllipseInRect(ctx, CGRectMake(10.4, 13.8, 3.2, 3.2));
            break;
        }
        case OTIconWifi: {
            CGContextMoveToPoint(ctx, 3.2, 8.6);
            CGContextAddQuadCurveToPoint(ctx, 12.0, 3.0, 20.8, 8.6);
            CGContextStrokePath(ctx);
            CGContextMoveToPoint(ctx, 6.4, 12.4);
            CGContextAddQuadCurveToPoint(ctx, 12.0, 8.6, 17.6, 12.4);
            CGContextStrokePath(ctx);
            CGContextMoveToPoint(ctx, 9.4, 16.2);
            CGContextAddQuadCurveToPoint(ctx, 12.0, 14.4, 14.6, 16.2);
            CGContextStrokePath(ctx);
            CGContextFillEllipseInRect(ctx, CGRectMake(10.2, 18.6, 3.6, 3.6));
            break;
        }
        case OTIconExternal: {
            UIBezierPath *box = [UIBezierPath bezierPath];
            [box moveToPoint:CGPointMake(13.0, 4.0)];
            [box addLineToPoint:CGPointMake(5.0, 4.0)];
            [box addQuadCurveToPoint:CGPointMake(3.6, 5.4) controlPoint:CGPointMake(3.6, 4.0)];
            [box addLineToPoint:CGPointMake(3.6, 19.0)];
            [box addQuadCurveToPoint:CGPointMake(5.0, 20.4) controlPoint:CGPointMake(3.6, 20.4)];
            [box addLineToPoint:CGPointMake(18.6, 20.4)];
            [box addQuadCurveToPoint:CGPointMake(20.0, 19.0) controlPoint:CGPointMake(20.0, 20.4)];
            [box addLineToPoint:CGPointMake(20.0, 11.0)];
            [box stroke];
            OTDrawLine(ctx, 12.0, 12.0, 21.4, 2.6);
            OTDrawLine(ctx, 21.4, 2.6, 21.4, 9.4);
            OTDrawLine(ctx, 21.4, 2.6, 14.6, 2.6);
            break;
        }
        case OTIconSort: {
            OTDrawLine(ctx, 7.0, 4.0, 7.0, 20.0);
            OTDrawLine(ctx, 3.8, 7.2, 7.0, 4.0);
            OTDrawLine(ctx, 10.2, 7.2, 7.0, 4.0);
            OTDrawLine(ctx, 17.0, 20.0, 17.0, 4.0);
            OTDrawLine(ctx, 13.8, 16.8, 17.0, 20.0);
            OTDrawLine(ctx, 20.2, 16.8, 17.0, 20.0);
            break;
        }
        case OTIconCast: {
            UIBezierPath *rect = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2.8, 5.0, 18.4, 13.0) cornerRadius:2.4];
            [rect stroke];
            CGContextMoveToPoint(ctx, 2.8, 21.0);
            CGContextAddQuadCurveToPoint(ctx, 8.4, 15.4, 8.4, 21.0);
            CGContextStrokePath(ctx);
            CGContextMoveToPoint(ctx, 2.8, 17.4);
            CGContextAddQuadCurveToPoint(ctx, 12.0, 11.8, 13.6, 21.0);
            CGContextStrokePath(ctx);
            CGContextFillEllipseInRect(ctx, CGRectMake(3.2, 19.4, 2.4, 2.4));
            break;
        }
        case OTIconVolume: {
            CGContextMoveToPoint(ctx, 3.6, 9.4);
            CGContextAddLineToPoint(ctx, 7.4, 9.4);
            CGContextAddLineToPoint(ctx, 12.0, 5.2);
            CGContextAddLineToPoint(ctx, 12.0, 18.8);
            CGContextAddLineToPoint(ctx, 7.4, 14.6);
            CGContextAddLineToPoint(ctx, 3.6, 14.6);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            CGContextMoveToPoint(ctx, 15.0, 9.0);
            CGContextAddQuadCurveToPoint(ctx, 18.0, 12.0, 15.0, 15.0);
            CGContextStrokePath(ctx);
            CGContextMoveToPoint(ctx, 17.4, 6.4);
            CGContextAddQuadCurveToPoint(ctx, 22.0, 12.0, 17.4, 17.6);
            CGContextStrokePath(ctx);
            break;
        }
        case OTIconMute: {
            CGContextMoveToPoint(ctx, 3.6, 9.4);
            CGContextAddLineToPoint(ctx, 7.4, 9.4);
            CGContextAddLineToPoint(ctx, 12.0, 5.2);
            CGContextAddLineToPoint(ctx, 12.0, 18.8);
            CGContextAddLineToPoint(ctx, 7.4, 14.6);
            CGContextAddLineToPoint(ctx, 3.6, 14.6);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            OTDrawLine(ctx, 15.4, 9.4, 21.0, 15.0);
            OTDrawLine(ctx, 21.0, 9.4, 15.4, 15.0);
            break;
        }
        case OTIconSeekBack: {
            CGContextAddArc(ctx, 12.0, 12.0, 8.2, 0.0, M_PI * 1.55, 0);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 12.0, 12.0, 12.0, 3.8);
            OTDrawLine(ctx, 12.0, 3.8, 16.4, 6.8);
            OTDrawLine(ctx, 12.0, 3.8, 8.4, 7.4);
            break;
        }
        case OTIconSeekForward: {
            CGContextAddArc(ctx, 12.0, 12.0, 8.2, M_PI, -M_PI * 0.55, 1);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 12.0, 12.0, 12.0, 3.8);
            OTDrawLine(ctx, 12.0, 3.8, 15.6, 7.4);
            OTDrawLine(ctx, 12.0, 3.8, 8.4, 6.8);
            break;
        }
        case OTIconMic: {
            UIBezierPath *capsule = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(9.2, 2.6, 5.6, 11.2) cornerRadius:2.8];
            [capsule stroke];
            CGContextMoveToPoint(ctx, 5.4, 11.4);
            CGContextAddQuadCurveToPoint(ctx, 12.0, 19.0, 18.6, 11.4);
            CGContextStrokePath(ctx);
            OTDrawLine(ctx, 12.0, 17.6, 12.0, 21.4);
            OTDrawLine(ctx, 8.6, 21.4, 15.4, 21.4);
            break;
        }
        case OTIconGrid: {
            UIBezierPath *a = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.2, 3.2, 7.6, 7.6) cornerRadius:1.8];
            [a fill];
            UIBezierPath *b = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(13.2, 3.2, 7.6, 7.6) cornerRadius:1.8];
            [b fill];
            UIBezierPath *c = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.2, 13.2, 7.6, 7.6) cornerRadius:1.8];
            [c fill];
            UIBezierPath *d = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(13.2, 13.2, 7.6, 7.6) cornerRadius:1.8];
            [d fill];
            break;
        }
        default: {
            CGContextStrokeEllipseInRect(ctx, CGRectMake(4.0, 4.0, 16.0, 16.0));
            break;
        }
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *)brandMark:(CGFloat)size
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat s = size / 48.0;
    CGContextScaleCTM(ctx, s, s);

    UIColor *pink = [self colorWithHex:0xED5564];
    UIColor *purple = [self colorWithHex:0xB44CF0];

    UIBezierPath *note = [UIBezierPath bezierPath];
    [note moveToPoint:CGPointMake(30.0, 6.0)];
    [note addLineToPoint:CGPointMake(30.0, 31.0)];
    [note addCurveToPoint:CGPointMake(22.5, 40.5)
             controlPoint1:CGPointMake(30.0, 35.5)
             controlPoint2:CGPointMake(26.8, 40.5)];
    [note addCurveToPoint:CGPointMake(16.4, 34.6)
             controlPoint1:CGPointMake(19.1, 40.5)
             controlPoint2:CGPointMake(16.4, 37.9)];
    [note addCurveToPoint:CGPointMake(24.0, 27.8)
             controlPoint1:CGPointMake(16.4, 31.2)
             controlPoint2:CGPointMake(19.7, 27.8)];
    [note addCurveToPoint:CGPointMake(27.2, 28.4)
             controlPoint1:CGPointMake(25.1, 27.8)
             controlPoint2:CGPointMake(26.2, 28.0)];
    [note addLineToPoint:CGPointMake(27.2, 14.4)];
    [note addCurveToPoint:CGPointMake(38.6, 20.2)
             controlPoint1:CGPointMake(33.6, 14.8)
             controlPoint2:CGPointMake(38.6, 16.8)];
    [note addCurveToPoint:CGPointMake(34.6, 25.4)
             controlPoint1:CGPointMake(38.6, 23.4)
             controlPoint2:CGPointMake(37.0, 25.4)];
    [note addCurveToPoint:CGPointMake(32.6, 25.0)
             controlPoint1:CGPointMake(33.9, 25.4)
             controlPoint2:CGPointMake(33.2, 25.2)];
    [note addLineToPoint:CGPointMake(32.6, 10.2)];
    [note closePath];
    [note fill];

    CGContextSetBlendMode(ctx, kCGBlendModeSourceAtop);
    CGGradientRef gradient = [self gradientFrom:pink to:purple];
    CGContextDrawLinearGradient(ctx,
                                gradient,
                                CGPointMake(16.0, 6.0),
                                CGPointMake(36.0, 42.0),
                                0);
    CGGradientRelease(gradient);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (CGGradientRef)gradientFrom:(UIColor *)from to:(UIColor *)to
{
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    NSArray *colors = @[(id)from.CGColor, (id)to.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, NULL);
    CGColorSpaceRelease(space);
    return gradient;
}

+ (UIImage *)musicPlaceholder:(CGFloat)size
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [self surfaceHigh].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, size, size));
    CGContextSetStrokeColorWithColor(ctx, [self outline].CGColor);
    CGContextSetLineWidth(ctx, MAX(1.5, size * 0.02));
    CGFloat pad = size * 0.30;
    CGContextStrokeEllipseInRect(ctx, CGRectMake(pad, size * 0.55, size * 0.16, size * 0.16));
    OTDrawLine(ctx, size * 0.46, size * 0.63, size * 0.46, pad);
    OTDrawLine(ctx, size * 0.46, pad, size * 0.70, size * 0.38);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIButton *)iconButton:(OTIcon)icon
                    size:(CGFloat)size
                   color:(UIColor *)color
                  target:(id)target
                  action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 44.0, 44.0);
    [button setImage:[self icon:icon size:size] forState:UIControlStateNormal];
    button.tintColor = color;
    if (target && action) {
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    return button;
}

#pragma mark - Appearance

+ (void)styleNavigationBar:(UINavigationBar *)bar
{
    bar.translucent = NO;
    bar.barStyle = UIBarStyleBlack;
    bar.barTintColor = [self background];
    bar.tintColor = [self primary];
    bar.shadowImage = [UIImage new];
    [bar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    bar.titleTextAttributes = @{
        NSForegroundColorAttributeName: [self text],
        NSFontAttributeName: [self titleMedium]
    };
}

+ (void)styleTableView:(UITableView *)tableView
{
    tableView.backgroundColor = [self background];
    tableView.separatorColor = [self colorWithHex:0x2C2A31];
    tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
    tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    tableView.rowHeight = 64.0;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

+ (void)styleCollectionView:(UICollectionView *)collectionView
{
    collectionView.backgroundColor = [self background];
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    collectionView.showsHorizontalScrollIndicator = NO;
}

+ (void)roundCorners:(UIView *)view radius:(CGFloat)radius
{
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
}

+ (void)applyShadow:(UIView *)view
{
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.22;
    view.layer.shadowRadius = 8.0;
    view.layer.shadowOffset = CGSizeMake(0, 3);
}

+ (void)showToast:(NSString *)text inView:(UIView *)view
{
    [self showToast:text inView:view duration:2.4];
}

+ (void)showToast:(NSString *)text inView:(UIView *)view duration:(NSTimeInterval)duration
{
    if (!view || text.length == 0) {
        return;
    }
    UIView *toast = [[UIView alloc] initWithFrame:CGRectZero];
    toast.backgroundColor = [self surfaceHighest];
    toast.layer.cornerRadius = 14.0;
    toast.layer.borderWidth = 0.5;
    toast.layer.borderColor = [self separator].CGColor;
    toast.alpha = 0.0;
    toast.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.textColor = [self text];
    label.font = [self bodyMedium];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;

    CGFloat maxWidth = MIN(view.bounds.size.width - 64.0, 420.0);
    CGSize size = [label sizeThatFits:CGSizeMake(maxWidth - 32.0, CGFLOAT_MAX)];
    CGFloat width = MIN(maxWidth, size.width + 32.0);
    CGFloat height = size.height + 22.0;

    toast.frame = CGRectMake((view.bounds.size.width - width) / 2.0,
                             view.bounds.size.height - height - 96.0,
                             width, height);
    label.frame = CGRectMake(16.0, 11.0, width - 32.0, height - 22.0);
    [toast addSubview:label];
    [view addSubview:toast];

    [UIView animateWithDuration:0.2 animations:^{
        toast.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:duration options:0 animations:^{
            toast.alpha = 0.0;
        } completion:^(BOOL done) {
            [toast removeFromSuperview];
        }];
    }];
}

#pragma mark - Format

+ (NSString *)formatTime:(double)seconds
{
    if (seconds < 0 || !isfinite(seconds)) {
        return @"0:00";
    }
    int total = (int)floor(seconds + 0.5);
    int h = total / 3600;
    int m = (total % 3600) / 60;
    int s = total % 60;
    if (h > 0) {
        return [NSString stringWithFormat:@"%d:%02d:%02d", h, m, s];
    }
    return [NSString stringWithFormat:@"%d:%02d", m, s];
}

+ (NSString *)formatCount:(long long)count
{
    if (count >= 1000000000LL) {
        return [NSString stringWithFormat:@"%.1f mil M", count / 1000000000.0];
    }
    if (count >= 1000000LL) {
        return [NSString stringWithFormat:@"%.1f M", count / 1000000.0];
    }
    if (count >= 1000LL) {
        return [NSString stringWithFormat:@"%.1f mil", count / 1000.0];
    }
    return [NSString stringWithFormat:@"%lld", count];
}

+ (NSString *)formatBytes:(unsigned long long)bytes
{
    if (bytes >= 1024ULL * 1024ULL * 1024ULL) {
        return [NSString stringWithFormat:@"%.1f GB", bytes / (1024.0 * 1024.0 * 1024.0)];
    }
    if (bytes >= 1024ULL * 1024ULL) {
        return [NSString stringWithFormat:@"%.1f MB", bytes / (1024.0 * 1024.0)];
    }
    if (bytes >= 1024ULL) {
        return [NSString stringWithFormat:@"%.0f KB", bytes / 1024.0];
    }
    return [NSString stringWithFormat:@"%llu B", bytes];
}

+ (BOOL)isWide
{
    return [UIScreen mainScreen].bounds.size.width >= 700.0;
}

+ (CGFloat)contentWidthForWidth:(CGFloat)width
{
    return MIN(width - 32.0, 980.0);
}

+ (CGFloat)columnsForWidth:(CGFloat)width
{
    if (width >= 980.0) return 4.0;
    if (width >= 700.0) return 3.0;
    return 2.0;
}

@end
