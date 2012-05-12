#import "ScrollLayer.h"
#import "CCNode+BeforeAfterVisitChildren.h"

#define kMinVelocity              3.0
#define kDecelerationRate         0.95
#define kSetContentOffsetDuration 2

@interface ScrollLayer ()
- (void)_decelerate:(ccTime)dt;
- (CGPoint)_constrainedPosition:(CGPoint)p;
- (void)_moveBy:(CGPoint)dx;
- (void)_moveTo:(CGPoint)newPos animated:(BOOL)animated;
@end

@implementation ScrollLayer

@synthesize visibleRect, clipsToBounds, scrollDelegate, scrollingEnabled, directionLock, dragging;

// FYI default anchor point is (0,0) so node space has origin in
// lower-left corner with X to the right and Y upwards.

- (id)init {
  if ((self = [super init])) {
    self.position = CGPointZero;

    CGSize defaultSize = [[CCDirector sharedDirector] winSize];
    self.visibleRect = (CGRect) { .origin = CGPointZero, .size = defaultSize };
    self.contentSize  = defaultSize;
  
    self.scrollingEnabled = YES;
    self.clipsToBounds = YES;
  }
  return self;
}

#pragma mark clipping

// Clip children nodes to the visible rect. {before,after}VisitChildren is defined in
// a CCNode category. Note: OpenGL works in pixels not iOS logical "points" hence the
// scaling here.

- (void)beforeVisitChildren {
  if (!clipsToBounds)
    return;  
  
  CGFloat scaleToPixels = [[CCDirector sharedDirector] contentScaleFactor];

  glEnable(GL_SCISSOR_TEST);

  glScissor(self.visibleRect.origin.x    * scaleToPixels,
            self.visibleRect.origin.y    * scaleToPixels,
            self.visibleRect.size.width  * scaleToPixels,
            self.visibleRect.size.height * scaleToPixels);
}

- (void)afterVisitChildren {
  if (!clipsToBounds)
    return;  

  glDisable(GL_SCISSOR_TEST);
}

#pragma mark touch handler registration

- (void)onEnter {
  [super onEnter];
  [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (void)onExit {
  [super onExit];
  [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
}

#pragma mark touch handling

- (void)_clearTrackingState {
  dragStartPoint = CGPointZero;
  prevTimestamp = 0;

  direction = CGPointZero;
  velocity = 0;

  autoMoving = NO;
  autoMoveToPoint = CGPointZero;
  
  dragging = NO;

  [[CCScheduler sharedScheduler] unscheduleSelector:@selector(_decelerate:) forTarget:self];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
  if (!self.visible || !self.scrollingEnabled)
    return NO;

  CGPoint touchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];

  if (CGRectContainsPoint(self.visibleRect, touchPoint)) {
    [self _clearTrackingState];    
    
    dragStartPoint = touchPoint;
    prevTimestamp = touch.timestamp;

    return YES;
  }

  return NO;
}

- (CGPoint)_swipeVectorFromTouches:(UITouch *)touch {
  CGPoint currTouchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
  CGPoint prevTouchPoint = [[CCDirector sharedDirector] convertToGL:[touch previousLocationInView:touch.view]];
  
  CGPoint swipeVector = ccpSub(currTouchPoint, prevTouchPoint);
  
  switch (directionLock) {
    case kScrollLayerDirectionLockNone:                          break;
    case kScrollLayerDirectionLockHorizontal: swipeVector.y = 0; break;
    case kScrollLayerDirectionLockVertical:   swipeVector.x = 0; break;
  }
  
  NSTimeInterval deltaTime = touch.timestamp - prevTimestamp;
  prevTimestamp = touch.timestamp;
  
  if (deltaTime > 0)
    velocity = (ccpLength(swipeVector) / deltaTime);

  direction = ccpNormalize(swipeVector);

  return swipeVector;
}

- (void)ccTouchMoved:(UITouch*)touch withEvent:(UIEvent*)event {
  if (!self.visible || !self.scrollingEnabled)
    return;
  
  if (!dragging) {
    dragging = YES;
    [self.scrollDelegate scrollLayerWillBeginDragging:self];
  }
  
  CGPoint swipeVector = [self _swipeVectorFromTouches:touch];
  [self _moveBy:swipeVector];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
  if (!self.visible || !self.scrollingEnabled)
    return;
  
  [self _swipeVectorFromTouches:touch];
  
  dragging = NO;
  
  if (velocity > kMinVelocity) {
    [self.scrollDelegate scrollLayerDidEndDragging:self willDecelerate:YES];
    [self.scrollDelegate scrollLayerWillBeginDecelerating:self];
    
    [[CCScheduler sharedScheduler] scheduleSelector:@selector(_decelerate:) forTarget:self interval:0 paused:NO];
  } else {
    [self.scrollDelegate scrollLayerDidEndDragging:self willDecelerate:NO];
    [self _clearTrackingState];
  }
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
  [self _clearTrackingState];
}

#pragma mark internal

- (void)_decelerate:(ccTime)dt {
  self.position = [self _constrainedPosition:ccpAdd(self.position, ccpMult(direction, velocity * dt))];
  [self.scrollDelegate scrollLayerDidScroll:self];
  
  BOOL shouldStop = (autoMoving) 
    ? (ccpDistance(autoMoveToPoint, self.position) <= 1)
    : ((velocity *= kDecelerationRate) < kMinVelocity);

  if (shouldStop)
    [self _clearTrackingState];
}

- (CGPoint)_constrainedPosition:(CGPoint)p {
  CGFloat visibleLeft   = self.visibleRect.origin.x;
  CGFloat visibleBottom = self.visibleRect.origin.y;
  CGFloat visibleRight  = self.visibleRect.origin.x + self.visibleRect.size.width;
  CGFloat visibleTop    = self.visibleRect.origin.y + self.visibleRect.size.height;
  
  CGFloat virtualWidth  = self.contentSize.width;
  CGFloat virtualHeight = self.contentSize.height;
  
  if (p.x > visibleLeft)   p.x = visibleLeft;
  if (p.y > visibleBottom) p.y = visibleBottom;
  
  if (p.x + virtualWidth  < visibleRight) p.x = visibleRight - virtualWidth;
  if (p.y + virtualHeight < visibleTop)   p.y = visibleTop   - virtualHeight;
  
  return p;
}

- (void)_moveBy:(CGPoint)dx {
  self.position = [self _constrainedPosition:ccpAdd(self.position, dx)];
  [scrollDelegate scrollLayerDidScroll:self];
}

- (void)_moveTo:(CGPoint)newPos animated:(BOOL)animated {
  self.position = [self _constrainedPosition:newPos];
  [scrollDelegate scrollLayerDidScroll:self];
}

#pragma mark Public API

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
  CGPoint dx = ccpSub(self.visibleRect.origin, contentOffset);
  
  [self _clearTrackingState];

  if (!animated) {
    [self _moveBy:dx];
  } else {
    autoMoving = YES;
    autoMoveToPoint = [self _constrainedPosition:ccpAdd(self.position, dx)];
    
    direction = ccpNormalize(dx);
    velocity  = ccpLength(dx) / kSetContentOffsetDuration;
    
    [[CCScheduler sharedScheduler] scheduleSelector:@selector(_decelerate:) forTarget:self interval:0 paused:NO];
  }
}

@end
