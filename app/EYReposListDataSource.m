#import "EYReposListDataSource.h"
@implementation EYReposListDataSource

// Number of rows
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return 5;
}

// Value for cell
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex
{
  if ([[aTableColumn identifier] compare:@"icon"] == 0)
    return [NSImage imageNamed:@"repo_icon_small"];
  else
    return @"Test Repo";
}

@end
