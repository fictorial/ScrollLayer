#import "ScrollLayer.h"
#import "CCNode+BeforeAfterVisitChildren.h"

#define kMinVelocity 3.0
#define kDecelerationRate 0.95

@interface ScrollLayer ()
- (void)decelerate:(ccTime)dt;
@end

@implementation ScrollLayer

@synthesize visibleRect, scrollDelegate, scrollingEnabled;

// FYI default anchor point is (0,0) so node space has origin in 
// lower-left corner with X to the right and Y upwards.    

- (id)init {
  if ((self = [super initWithColor:ccc4(128, 128, 128, 255)])) {
    CGSize defaultSize = [[CCDirector sharedDirector] winSize];
    self.position = CGPointZero;
    self.visibleRect = (CGRect) { .origin = CGPointZero, .size = defaultSize };
    self.contentSize  = defaultSize;
    self.scrollingEnabled = YES;
  }
  return self;
}

- (CGPoint)_constrainPoint:(CGPoint)p {
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

// Clip children nodes to the visible rect. {before,after}VisitChildren is defined in 
// a CCNode category. Note: OpenGL works in pixels not iOS logical "points" hence the
// scaling here.

- (void)beforeVisitChildren {
  CGFloat scaleToPixels = [[CCDirector sharedDirector] contentScaleFactor];
  
  glEnable(GL_SCISSOR_TEST);
  
  glScissor(self.visibleRect.origin.x    * scaleToPixels,
            self.visibleRect.origin.y    * scaleToPixels,
            self.visibleRect.size.width  * scaleToPixels,
            self.visibleRect.size.height * scaleToPixels);
}

- (void)afterVisitChildren {
  glDisable(GL_SCISSOR_TEST);
}

- (void)onEnter {
  [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (void)onExit {
  [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
}

- (void)_clearTrackingState {
  prevTimestamp = 0;
  direction = CGPointZero;
  velocity = 0;
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
  if (!self.visible || !self.scrollingEnabled)
    return NO;
  
  CGPoint touchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
  
  if (CGRectContainsPoint(self.visibleRect, touchPoint)) {
    [self _clearTrackingState];
    return YES;
  }
  
  return NO;
}

- (void)ccTouchMoved:(UITouch*)touch withEvent:(UIEvent*)event {
  if (!self.visible || !self.scrollingEnabled)
    return;
  
  CGPoint touchPoint     = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];  
  CGPoint touchPointPrev = [[CCDirector sharedDirector] convertToGL:[touch previousLocationInView:touch.view]];  
  
  if (prevTimestamp == 0) 
    prevTimestamp = touch.timestamp;
  
  CGFloat dt = touch.timestamp - prevTimestamp;
  if (dt == 0) return;
  
  prevTimestamp = touch.timestamp;
  direction     = ccpSub(touchPoint, touchPointPrev);
  velocity      = ccpLength(direction) / dt;
  direction     = ccpNormalize(direction);  
  
  self.position = [self _constrainPoint:ccpAdd(self.position, ccpSub(touchPoint, touchPointPrev))];
  
  [scrollDelegate scrollLayerDidScroll:self];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
  if (self.visible && self.scrollingEnabled && velocity > kMinVelocity) {
    [[CCScheduler sharedScheduler] unscheduleSelector:@selector(decelerate:) forTarget:self];
    [[CCScheduler sharedScheduler] scheduleSelector:@selector(decelerate:) forTarget:self interval:0 paused:NO];  
  }
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
  [self _clearTrackingState];
}

- (void)decelerate:(ccTime)dt {
  self.position = [self _constrainPoint:ccpAdd(self.position, ccpMult(direction, velocity * dt))];  
  [self.scrollDelegate scrollLayerDidScroll:self];

  if ((velocity *= kDecelerationRate) < kMinVelocity)
    [[CCScheduler sharedScheduler] unscheduleSelector:@selector(decelerate:) forTarget:self];
}

@end
