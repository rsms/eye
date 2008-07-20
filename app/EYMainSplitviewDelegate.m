#import "EYMainSplitviewDelegate.h"

@implementation EYMainSplitviewDelegate

#define MIN_WIDTH 100.0
#define MAX_WIDTH 400.0

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
  return MIN_WIDTH;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
  return MAX_WIDTH;
}

- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
  NSSize dragger_size = [dragger frame].size;
  NSRect left_frame = [[[splitview subviews] objectAtIndex:0] frame];
  return NSMakeRect(left_frame.size.width-dragger_size.width,
                    left_frame.size.height-dragger_size.height,
                    dragger_size.width,
                    dragger_size.height);
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
  NSView *v0 = [[splitview subviews] objectAtIndex:0];
  NSRect v0frame = [v0 frame];
  v0frame.size.height = [sender frame].size.height;
  if (v0frame.size.width > MAX_WIDTH)
    v0frame.size.width = MAX_WIDTH;
  else if (v0frame.size.width < MIN_WIDTH)
    v0frame.size.width = MIN_WIDTH;
  [v0 setFrame:v0frame];
  
  NSView *v1 = [[splitview subviews] objectAtIndex:1];
  NSRect v1frame = [v1 frame];
  v1frame.size.height = [sender frame].size.height;
  v1frame.size.width = [sender frame].size.width - v0frame.size.width;
  [v1 setFrame:v1frame];
}


@end
