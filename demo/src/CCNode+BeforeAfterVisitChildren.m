#import "CCNode+BeforeAfterVisitChildren.h"

@implementation CCNode (BeforeAfterVisitChildren)

- (void)beforeVisitChildren {
}

- (void)afterVisitChildren {
}

// Current as of v1.0.0rc3

-(void) visit
{
	// quick return if not visible
	if (!visible_)
		return;
	
	glPushMatrix();
	
	if ( grid_ && grid_.active) {
		[grid_ beforeDraw];
		[self transformAncestors];
	}
  
	[self transform];
	
	if(children_) {
    [self beforeVisitChildren];    // added
    
		ccArray *arrayData = children_->data;
		NSUInteger i = 0;
		
		// draw children zOrder < 0
		for( ; i < arrayData->num; i++ ) {
			CCNode *child = arrayData->arr[i];
			if ( [child zOrder] < 0 )
				[child visit];
			else
				break;
		}
		
		// self draw
		[self draw];
		
		// draw children zOrder >= 0
		for( ; i < arrayData->num; i++ ) {
			CCNode *child =  arrayData->arr[i];
			[child visit];
		}
    
    [self afterVisitChildren];     // added
	} else
		[self draw];
	
	if ( grid_ && grid_.active)
		[grid_ afterDraw:self];
	
	glPopMatrix();
}

@end
