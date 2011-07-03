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

- (id)init {
	if ((self = [super initWithColor:ccc4(192,192,192,255)])) {
    ScrollLayer *scrollLayer = [ScrollLayer node];
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    // virtual region is the same rect as the window.
    
    scrollLayer.position    = CGPointZero;
    scrollLayer.contentSize = winSize;
    
    // visible rect is a window into the virtual region.

    scrollLayer.visibleRect = CGRectMake(winSize.width/4, winSize.height/4, winSize.width/2, winSize.height/2);
    
    [scrollLayer addChild:[self _makeColoredSprite:ccYELLOW pos:CGPointMake(blockSize, blockSize)]];
    [scrollLayer addChild:[self _makeColoredSprite:ccBLUE   pos:CGPointMake(blockSize, winSize.height - blockSize)]];
    [scrollLayer addChild:[self _makeColoredSprite:ccBLACK  pos:CGPointMake(winSize.width - blockSize, blockSize)]];
    [scrollLayer addChild:[self _makeColoredSprite:ccORANGE pos:CGPointMake(winSize.width - blockSize, winSize.height - blockSize)]];
    [scrollLayer addChild:[self _makeColoredSprite:ccWHITE  pos:CGPointMake(winSize.width/2, winSize.height/2)]];

    [self addChild:scrollLayer];
	}
  
	return self;
}

@end
