#import "HelloWorldLayer.h"
#import "ScrollLayer.h"

static const CGFloat blockSize = 50;

@implementation HelloWorldLayer

+ (CCScene *)scene {
	CCScene* scene = [CCScene node];
  [scene addChild:[HelloWorldLayer node]];
  return scene;
}

- (CCSprite *)_makeColoredSprite:(ccColor3B)color pos:(CGPoint)pos {
  CCSprite* aSprite = [CCSprite node];
  aSprite.color = color;
  aSprite.textureRect = CGRectMake(0,0,blockSize,blockSize);
  aSprite.position = pos;
  return aSprite;
}

- (void)_doSampleMove:(ccTime)dt {
  ScrollLayer *scrollLayer = (ScrollLayer *)[self getChildByTag:999];
  CGSize winSize = [[CCDirector sharedDirector] winSize];
  [scrollLayer setContentOffset:ccp(winSize.width/2, winSize.height/2) animated:YES];
  [[CCScheduler sharedScheduler] unscheduleAllSelectorsForTarget:self];
}

- (id)init {
	if ((self = [super initWithColor:ccc4(192,192,192,255)])) {
    ScrollLayer *scrollLayer = [ScrollLayer node];
    scrollLayer.tag = 999;
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    // virtual region is the same rect as the window.
    
    scrollLayer.position    = CGPointZero;
    scrollLayer.contentSize = winSize;
    
    // scrollLayer.directionLock = kScrollLayerDirectionLockVertical;
    
    // visible rect is a window into the virtual region.

    scrollLayer.visibleRect = CGRectMake(winSize.width/4, winSize.height/4, winSize.width/2, winSize.height/2);
    
    [scrollLayer addChild:[self _makeColoredSprite:ccYELLOW pos:CGPointMake(blockSize, blockSize)]];
    [scrollLayer addChild:[self _makeColoredSprite:ccBLUE   pos:CGPointMake(blockSize, winSize.height - blockSize)]];
    [scrollLayer addChild:[self _makeColoredSprite:ccRED    pos:CGPointMake(winSize.width - blockSize, blockSize)]];
    [scrollLayer addChild:[self _makeColoredSprite:ccORANGE pos:CGPointMake(winSize.width - blockSize, winSize.height - blockSize)]];
    [scrollLayer addChild:[self _makeColoredSprite:ccWHITE  pos:CGPointMake(winSize.width/2, winSize.height/2)]];

    CCSprite* aSprite = [CCSprite node];
    aSprite.color = ccBLACK;
    aSprite.textureRect = CGRectMake(0,0,winSize.width/2,winSize.height/2);
    aSprite.position = CGPointMake(winSize.width/2, winSize.height/2);
    aSprite.anchorPoint = ccp(0.5,0.5);
    [self addChild:aSprite];

    [self addChild:scrollLayer];
    
    [[CCScheduler sharedScheduler] scheduleSelector:@selector(_doSampleMove:) forTarget:self interval:3.0 paused:NO];
	}
  
	return self;
}

@end
