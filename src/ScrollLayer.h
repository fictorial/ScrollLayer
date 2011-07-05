#import "cocos2d.h"

@class ScrollLayer;

@protocol ScrollLayerDelegate <NSObject>
- (void)scrollLayerDidScroll:(ScrollLayer *)scrollLayer;
- (void)scrollLayerWillBeginDragging:(ScrollLayer *)scrollLayer;
- (void)scrollLayerDidEndDragging:(ScrollLayer *)scrollLayer willDecelerate:(BOOL)willDecelerate;
- (void)scrollLayerWillBeginDecelerating:(ScrollLayer *)scrollLayer;
@end

enum {
  kScrollLayerDirectionLockNone,
  kScrollLayerDirectionLockHorizontal,
  kScrollLayerDirectionLockVertical
};

typedef NSUInteger ScrollLayerDirectionLock;

// A ScrollLayer is a CCLayer that provides a visible "window"
// into a larger virtual region.  Finger swipes allow the 
// virtual region to be panned which simulates scrolling inside
// the visible window.
//
// The virtual region is the entire layer and is thus defined
// by the CCNode properties position and contentSize.
//
// The visible "window" is defined by a rectangle called visibleRect.
//
// By default, the entire window is used as both the visible rect and 
// virtual region.

// Things that are unsupported include:
// - bouncing
// - zooming
// - paging
// - scroll bars / indicators
// - arbitrary deceleration rate (e.g. normal, fast)
// - scroll to "top" (by tapping status bar)

@interface ScrollLayer : CCLayer {
  CGRect visibleRect;
  BOOL clipsToBounds;
  id <ScrollLayerDelegate> scrollDelegate;
  BOOL scrollingEnabled;
  NSTimeInterval prevTimestamp;
  CGFloat velocity;
  CGPoint direction;
  CGPoint destinationPoint;
  BOOL movingToPoint;
  ScrollLayerDirectionLock directionLock;
}

@property (nonatomic, assign) CGRect visibleRect;
@property (nonatomic, assign) BOOL clipsToBounds;
@property (nonatomic, assign) id <ScrollLayerDelegate> scrollDelegate;
@property (nonatomic, assign) BOOL scrollingEnabled;
@property (nonatomic, assign) ScrollLayerDirectionLock directionLock;

// Moves the scroll layer such that the given point is at the visibleRect origin.
// If not animated, the layer position change is instant. Else, a constant velocity
// is set to move the layer over the course of 2 seconds.

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

@end
