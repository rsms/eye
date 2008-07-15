#import "EYLeftcolBarBgView.h"

@implementation EYLeftcolBarBgView


- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    NSRect fr = [self frame];
    [self setFrame:NSMakeRect(ceil(fr.origin.x), ceil(fr.origin.y), ceil(fr.size.width), ceil(fr.size.height))];
  }
  return self;
}


- (void)drawRect:(NSRect)rect {
  NSImage *im = [NSImage imageNamed:@"leftcol_bg"];
  // Always draw full height or we'll get strange stretching
  NSRect in_rect = [self bounds];
  in_rect.origin.x = rect.origin.x;
  in_rect.size.width = rect.size.width;
  [im drawInRect:in_rect
        fromRect:NSMakeRect(0.0, 0.0, [im size].width, [im size].height)
       operation:NSCompositeCopy
        fraction:1.0];
}

@end
