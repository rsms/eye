#import "EYMainSplitviewDelegate.h"

@implementation EYMainSplitviewDelegate


- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
  return 100.0;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
  return 400.0;
}

- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
  NSSize dragger_size = [dragger frame].size;
  NSRect left_frame = [[[splitview subviews] objectAtIndex:0] frame];
  return NSMakeRect(left_frame.size.width-dragger_size.width,
                    left_frame.size.height-dragger_size.height,
                    dragger_size.width,
                    dragger_size.height);
}


@end
