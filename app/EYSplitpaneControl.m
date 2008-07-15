#import "EYSplitpaneControl.h"

@implementation EYSplitpaneControl

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    NSRect fr = [self frame];
    [self setFrame:NSMakeRect(ceil(fr.origin.x), ceil(fr.origin.y), ceil(fr.size.width), ceil(fr.size.height))];
  }
  return self;
}

// - (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex

- (void)drawRect:(NSRect)rect {
  NSImage *im = [NSImage imageNamed:@"splitpange_control_h"];
  [im drawInRect:NSMakeRect(0.0, 0.0, [im size].width, [im size].height)
        fromRect:NSMakeRect(0.0, 0.0, [im size].width, [im size].height)
       operation:NSCompositeCopy
        fraction:1.0];
}

@end
