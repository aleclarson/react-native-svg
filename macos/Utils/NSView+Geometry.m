#import "NSView+Geometry.h"

@implementation NSView (Geometry)

- (NSPoint)center
{
  return (CGPoint){NSMidX(self.frame), NSMidY(self.frame)};
}

- (void)setCenter:(NSPoint)center
{
  NSPoint origin = self.frame.origin;
  origin.x -= center.x;
  origin.y -= center.y;

  self.frameOrigin = origin;
}

@end
