#import "RNSVGGlyphContext.h"
#import <React/RCTFont.h>
#import "RNSVGNode.h"
#import "RNSVGPropHelper.h"
#import "RNSVGFontData.h"
#import "RNSVGText.h"

// https://www.w3.org/TR/SVG/text.html#TSpanElement
@interface RNSVGGlyphContext ()
{
    // Current stack (one per node push/pop)
    NSMutableArray *_fontContext;

    // Unique input attribute lists (only added if node sets a value)
    NSMutableArray<NSArray<RNSVGLength*>*> *_xsContext;
    NSMutableArray<NSArray<RNSVGLength*>*> *_ysContext;
    NSMutableArray<NSArray<RNSVGLength*>*> *_dxsContext;
    NSMutableArray<NSArray<RNSVGLength*>*> *_dysContext;
    NSMutableArray<NSArray<RNSVGLength*>*> *_rsContext;

    // Unique index into attribute list (one per unique list)
    NSMutableArray<NSNumber*> *_xIndices;
    NSMutableArray<NSNumber*> *_yIndices;
    NSMutableArray<NSNumber*> *_dxIndices;
    NSMutableArray<NSNumber*> *_dyIndices;
    NSMutableArray<NSNumber*> *_rIndices;

    // Index of unique context used (one per node push/pop)
    NSMutableArray<NSNumber*> *_xsIndices;
    NSMutableArray<NSNumber*> *_ysIndices;
    NSMutableArray<NSNumber*> *_dxsIndices;
    NSMutableArray<NSNumber*> *_dysIndices;
    NSMutableArray<NSNumber*> *_rsIndices;

    // Calculated on push context, percentage and em length depends on parent font size
    CGFloat _fontSize;
    RNSVGFontData *_topFont;

    // Current accumulated values
    // https://www.w3.org/TR/SVG/types.html#DataTypeCoordinate
    // <coordinate> syntax is the same as that for <length>
    CGFloat _x;
    CGFloat _y;

    // https://www.w3.org/TR/SVG/types.html#Length
    CGFloat _dx;
    CGFloat _dy;

    // Current <list-of-coordinates> SVGLengthList
    // https://www.w3.org/TR/SVG/types.html#InterfaceSVGLengthList
    // https://www.w3.org/TR/SVG/types.html#DataTypeCoordinates

    // https://www.w3.org/TR/SVG/text.html#TSpanElementXAttribute
    NSArray<RNSVGLength*> *_xs;

    // https://www.w3.org/TR/SVG/text.html#TSpanElementYAttribute
    NSArray<RNSVGLength*> *_ys;

    // Current <list-of-lengths> SVGLengthList
    // https://www.w3.org/TR/SVG/types.html#DataTypeLengths

    // https://www.w3.org/TR/SVG/text.html#TSpanElementDXAttribute
    NSArray<RNSVGLength*> *_dxs;

    // https://www.w3.org/TR/SVG/text.html#TSpanElementDYAttribute
    NSArray<RNSVGLength*> *_dys;

    // Current <list-of-numbers> SVGLengthList
    // https://www.w3.org/TR/SVG/types.html#DataTypeNumbers

    // https://www.w3.org/TR/SVG/text.html#TSpanElementRotateAttribute
    NSArray<RNSVGLength*> *_rs;

    // Current attribute list index
    long _xsIndex;
    long _ysIndex;
    long _dxsIndex;
    long _dysIndex;
    long _rsIndex;

    // Current value index in current attribute list
    long _xIndex;
    long _yIndex;
    long _dxIndex;
    long _dyIndex;
    long _rIndex;

    // Top index of stack
    long _top;

    // Constructor parameters
    CGFloat _width;
    CGFloat _height;
}

- (void)pushContext:(RNSVGText*)node
               font:(NSDictionary*)font
                  x:(NSArray<RNSVGLength*>*)x
                  y:(NSArray<RNSVGLength*>*)y
             deltaX:(NSArray<RNSVGLength*>*)deltaX
             deltaY:(NSArray<RNSVGLength*>*)deltaY
             rotate:(NSArray<RNSVGLength*>*)rotate;

- (void)pushContext:(RNSVGGroup*)node
               font:(NSDictionary *)font;
@end

@implementation RNSVGGlyphContext

- (instancetype)initWithWidth:(CGFloat)width
                       height:(CGFloat)height
{
    if (self = [super init]) {
      _fontContext = [NSMutableArray new];
      _xsContext = [NSMutableArray new];
      _ysContext = [NSMutableArray new];
      _dxsContext = [NSMutableArray new];
      _dysContext = [NSMutableArray new];
      _rsContext = [NSMutableArray new];

     _xIndices = [NSMutableArray new];
      _yIndices = [NSMutableArray new];
      _dxIndices = [NSMutableArray new];
      _dyIndices = [NSMutableArray new];
      _rIndices = [NSMutableArray new];

      _xsIndices = [NSMutableArray new];
      _ysIndices = [NSMutableArray new];
      _dxsIndices = [NSMutableArray new];
      _dysIndices = [NSMutableArray new];
      _rsIndices = [NSMutableArray new];

      _fontSize = RNSVGFontData_DEFAULT_FONT_SIZE;
      _topFont = [RNSVGFontData Defaults];

      _xs = [NSArray new];
      _ys = [NSArray new];
      _dxs = [NSArray new];
      _dys = [NSArray new];
      _rs = [NSArray arrayWithObjects:[RNSVGLength lengthWithNumber:0], nil];

      _xIndex = -1;
      _yIndex = -1;
      _dxIndex = -1;
      _dyIndex = -1;
      _rIndex = -1;

      _width = width;
      _height = height;

      [_xsContext addObject:_xs];
      [_ysContext addObject:_ys];
      [_dxsContext addObject:_dxs];
      [_dysContext addObject:_dys];
      [_rsContext addObject:_rs];

      [_xIndices addObject:[NSNumber numberWithLong:_xIndex]];
      [_yIndices addObject:[NSNumber numberWithLong:_yIndex]];
      [_dxIndices addObject:[NSNumber numberWithLong:_dxIndex]];
      [_dyIndices addObject:[NSNumber numberWithLong:_dyIndex]];
      [_rIndices addObject:[NSNumber numberWithLong:_rIndex]];

      [_fontContext addObject:_topFont];
      [self pushIndices];
    }
    return self;
}

- (CTFontRef)getGlyphFont
{
    NSString *fontFamily = _topFont->fontFamily;
    NSNumber * fontSize = [NSNumber numberWithDouble:_topFont->fontSize];

    NSString * fontWeight = [RNSVGFontWeightToString(_topFont->fontWeight) lowercaseString];
    NSString * fontStyle = RNSVGFontStyleStrings[_topFont->fontStyle];

    BOOL fontFamilyFound = NO;
    NSArray *supportedFontFamilyNames = [UIFont familyNames];

    if ([supportedFontFamilyNames containsObject:fontFamily]) {
        fontFamilyFound = YES;
    } else {
        for (NSString *fontFamilyName in supportedFontFamilyNames) {
            if ([[UIFont fontNamesForFamilyName: fontFamilyName] containsObject:fontFamily]) {
                fontFamilyFound = YES;
                break;
            }
        }
    }
    fontFamily = fontFamilyFound ? fontFamily : nil;

    return (__bridge CTFontRef)[RCTFont updateFont:nil
                                        withFamily:fontFamily
                                              size:fontSize
                                            weight:fontWeight
                                             style:fontStyle
                                           variant:nil
                                   scaleMultiplier:1.0];
}

- (void)pushIndices
{
    [_xsIndices addObject:[NSNumber numberWithLong:_xsIndex]];
    [_ysIndices addObject:[NSNumber numberWithLong:_ysIndex]];
    [_dxsIndices addObject:[NSNumber numberWithLong:_dxsIndex]];
    [_dysIndices addObject:[NSNumber numberWithLong:_dysIndex]];
    [_rsIndices addObject:[NSNumber numberWithLong:_rsIndex]];
}

- (RNSVGFontData *)getFont
{
    return _topFont;
}

- (RNSVGFontData *)getTopOrParentFont:(RNSVGGroup *)child
{
    if (_top > 0) {
        return _topFont;
    } else {
        RNSVGGroup* parentRoot = [child getParentTextRoot];
        RNSVGFontData* Defaults = [RNSVGFontData Defaults];
        while (parentRoot != nil) {
            RNSVGFontData *map = [[parentRoot getGlyphContext] getFont];
            if (map != Defaults) {
                return map;
            }
            parentRoot = [parentRoot getParentTextRoot];
        }
        return Defaults;
    }
}

- (void)pushNode:(RNSVGGroup *)node andFont:(NSDictionary *)font
{
    RNSVGFontData *parent = [self getTopOrParentFont:node];
    _top++;
    if (font == nil) {
        [_fontContext addObject:parent];
        return;
    }
    RNSVGFontData *data = [RNSVGFontData initWithNSDictionary:font
                                                       parent:parent];
    _fontSize = data->fontSize;
    [_fontContext addObject:data];
    _topFont = data;
}

- (void)pushContext:(RNSVGGroup*)node
               font:(NSDictionary*)font
{
    [self pushNode:node andFont:font];
    [self pushIndices];
}

- (void)pushContext:(RNSVGText*)node
               font:(NSDictionary*)font
                  x:(NSArray<RNSVGLength*>*)x
                  y:(NSArray<RNSVGLength*>*)y
             deltaX:(NSArray<RNSVGLength*>*)deltaX
             deltaY:(NSArray<RNSVGLength*>*)deltaY
             rotate:(NSArray<RNSVGLength*>*)rotate
{
    [self pushNode:(RNSVGGroup*)node andFont:font];
    if (x != nil && [x count] != 0) {
        _xsIndex++;
        _xIndex = -1;
        [_xIndices addObject:[NSNumber numberWithLong:_xIndex]];
        _xs = x;
        [_xsContext addObject:_xs];
    }
    if (y != nil && [y count] != 0) {
        _ysIndex++;
        _yIndex = -1;
        [_yIndices addObject:[NSNumber numberWithLong:_yIndex]];
        _ys = y;
        [_ysContext addObject:_ys];
    }
    if (deltaX != nil && [deltaX count] != 0) {
        _dxsIndex++;
        _dxIndex = -1;
        [_dxIndices addObject:[NSNumber numberWithLong:_dxIndex]];
        _dxs = deltaX;
        [_dxsContext addObject:_dxs];
    }
    if (deltaY != nil && [deltaY count] != 0) {
        _dysIndex++;
        _dyIndex = -1;
        [_dyIndices addObject:[NSNumber numberWithLong:_dyIndex]];
        _dys = deltaY;
        [_dysContext addObject:_dys];
    }
    if (rotate != nil && [rotate count] != 0) {
        _rsIndex++;
        _rIndex = -1;
        [_rIndices addObject:[NSNumber numberWithLong:_rIndex]];
        _rs = rotate;
        [_rsContext addObject:_rs];
    }
    [self pushIndices];
}

- (void)popContext
{
    [_fontContext removeLastObject];
    [_xsIndices removeLastObject];
    [_ysIndices removeLastObject];
    [_dxsIndices removeLastObject];
    [_dysIndices removeLastObject];
    [_rsIndices removeLastObject];

    _top--;

    long x = _xsIndex;
    long y = _ysIndex;
    long dx = _dxsIndex;
    long dy = _dysIndex;
    long r = _rsIndex;

    _topFont = [_fontContext lastObject];

    _xsIndex = [[_xsIndices lastObject] longValue];
    _ysIndex = [[_ysIndices lastObject] longValue];
    _dxsIndex = [[_dxsIndices lastObject] longValue];
    _dysIndex = [[_dysIndices lastObject] longValue];
    _rsIndex = [[_rsIndices lastObject] longValue];

    if (x != _xsIndex) {
        [_xsContext removeObjectAtIndex:x];
        _xs = [_xsContext objectAtIndex:_xsIndex];
        _xIndex = [[_xIndices objectAtIndex:_xsIndex] longValue];
    }
    if (y != _ysIndex) {
        [_ysContext removeObjectAtIndex:y];
        _ys = [_ysContext objectAtIndex:_ysIndex];
        _yIndex = [[_yIndices objectAtIndex:_ysIndex] longValue];
    }
    if (dx != _dxsIndex) {
        [_dxsContext removeObjectAtIndex:dx];
        _dxs = [_dxsContext objectAtIndex:_dxsIndex];
        _dxIndex = [[_dxIndices objectAtIndex:_dxsIndex] longValue];
    }
    if (dy != _dysIndex) {
        [_dysContext removeObjectAtIndex:dy];
        _dys = [_dysContext objectAtIndex:_dysIndex];
        _dyIndex = [[_dyIndices objectAtIndex:_dysIndex] longValue];
    }
    if (r != _rsIndex) {
        [_rsContext removeObjectAtIndex:r];
        _rs = [_rsContext objectAtIndex:_rsIndex];
        _rIndex = [[_rIndices objectAtIndex:_rsIndex] longValue];
    }
}

+ (void)incrementIndices:(NSMutableArray *)indices topIndex:(long)topIndex
{
    for (long index = topIndex; index >= 0; index--) {
        long xIndex = [[indices  objectAtIndex:index] longValue];
        [indices setObject:[NSNumber numberWithLong:xIndex + 1] atIndexedSubscript:index];
    }
}

// https://www.w3.org/TR/SVG11/text.html#FontSizeProperty

/**
 * Get font size from context.
 * <p>
 * ‘font-size’
 * Value:       < absolute-size > | < relative-size > | < length > | < percentage > | inherit
 * Initial:     medium
 * Applies to:  text content elements
 * Inherited:   yes, the computed value is inherited
 * Percentages: refer to parent element's font size
 * Media:       visual
 * Animatable:  yes
 * <p>
 * This property refers to the size of the font from baseline to
 * baseline when multiple lines of text are set solid in a multiline
 * layout environment.
 * <p>
 * For SVG, if a < length > is provided without a unit identifier
 * (e.g., an unqualified number such as 128), the SVG user agent
 * processes the < length > as a height value in the current user
 * coordinate system.
 * <p>
 * If a < length > is provided with one of the unit identifiers
 * (e.g., 12pt or 10%), then the SVG user agent converts the
 * < length > into a corresponding value in the current user
 * coordinate system by applying the rules described in Units.
 * <p>
 * Except for any additional information provided in this specification,
 * the normative definition of the property is in CSS2 ([CSS2], section 15.2.4).
 */
- (CGFloat)getFontSize
{
    return _fontSize;
}

- (CGFloat)nextXWithDouble:(CGFloat)advance
{
    [RNSVGGlyphContext incrementIndices:_xIndices topIndex:_xsIndex];
    long nextIndex = _xIndex + 1;
    if (nextIndex < [_xs count]) {
        _dx = 0;
        _xIndex = nextIndex;
        RNSVGLength *length = [_xs objectAtIndex:nextIndex];
        _x = [RNSVGPropHelper fromRelative:length
                                   relative:_width
                                   fontSize:_fontSize];
    }
    _x += advance;
    return _x;
}

- (CGFloat)nextY
{
    [RNSVGGlyphContext incrementIndices:_yIndices topIndex:_ysIndex];
    long nextIndex = _yIndex + 1;
    if (nextIndex < [_ys count]) {
        _dy = 0;
        _yIndex = nextIndex;
        RNSVGLength *length = [_ys objectAtIndex:nextIndex];
        _y = [RNSVGPropHelper fromRelative:length
                                   relative:_height
                                   fontSize:_fontSize];
    }
    return _y;
}

- (CGFloat)nextDeltaX
{
    [RNSVGGlyphContext incrementIndices:_dxIndices topIndex:_dxsIndex];
    long nextIndex = _dxIndex + 1;
    if (nextIndex < [_dxs count]) {
        _dxIndex = nextIndex;
        RNSVGLength *length = [_dxs objectAtIndex:nextIndex];
        CGFloat val = [RNSVGPropHelper fromRelative:length
                                          relative:_width
                                          fontSize:_fontSize];
        _dx += val;
    }
    return _dx;
}

- (CGFloat)nextDeltaY
{
    [RNSVGGlyphContext incrementIndices:_dyIndices topIndex:_dysIndex];
    long nextIndex = _dyIndex + 1;
    if (nextIndex < [_dys count]) {
        _dyIndex = nextIndex;
        RNSVGLength *length = [_dys objectAtIndex:nextIndex];
        CGFloat val = [RNSVGPropHelper fromRelative:length
                                          relative:_height
                                          fontSize:_fontSize];
        _dy += val;
    }
    return _dy;
}

- (CGFloat)nextRotation
{
    [RNSVGGlyphContext incrementIndices:_rIndices topIndex:_rsIndex];
    long nextIndex = _rIndex + 1;
    long count = [_rs count];
    if (nextIndex < count) {
        _rIndex = nextIndex;
    } else {
        _rIndex = count - 1;
    }
    return [_rs[_rIndex] value];
}

- (CGFloat)getWidth
{
    return _width;
}

- (CGFloat)getHeight
{
    return _height;
}

@end
