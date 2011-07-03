#import "cocos2d.h"

@class ScrollLayer;

@protocol ScrollLayerDelegate <NSObject>
- (void)scrollLayerDidScroll:(ScrollLayer *)scrollLayer;
@end

// A ScrollLayer is a CCLayer that provides a visible "window"
// into a larger virtual region.  Finger swipes allow the 
// virtual region to be panned which simulates scrolling inside
// the visible window.
//
// The virtual region is the entire layer and is thus defined
// by the CCNode properties position and contentSize.
//
// The visible "window" is defined by a rectangle in layer-space
// called visibleRect.
//
// By default, the entire window is used as both the visible rect and 
// virtual region.

@interface ScrollLayer : CCLayerColor {
  CGRect visibleRect;
  id <ScrollLayerDelegate> scrollDelegate;
  BOOL scrollingEnabled;
  NSTimeInterval prevTimestamp;
  CGFloat velocity;
  CGPoint direction;
}

@property (nonatomic, assign) CGRect visibleRect;
@property (nonatomic, assign) id <ScrollLayerDelegate> scrollDelegate;
@property (nonatomic, assign) BOOL scrollingEnabled;

@end
