#import "cocos2d.h"

@interface CCNode (BeforeAfterVisitChildren)

- (void)beforeVisitChildren;
- (void)afterVisitChildren;

@end
