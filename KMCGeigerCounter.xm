#import "KMCGeigerCounter.h"

#define kHardwareFramesPerSecond 60

static NSTimeInterval const kNormalFrameDuration = 1.0 / kHardwareFramesPerSecond;

@interface KMCGeigerCounter () {
    CFTimeInterval _lastSecondOfFrameTimes[kHardwareFramesPerSecond];
}

@property (nonatomic, readwrite, getter = isRunning) BOOL running;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UILabel *meterLabel;

@property (nonatomic, retain) CADisplayLink *displayLink;

@property (nonatomic, assign) NSInteger frameNumber;

@end

@implementation KMCGeigerCounter

#pragma mark - Helpers

- (CFTimeInterval)lastFrameTime
{
    return _lastSecondOfFrameTimes[self.frameNumber % kHardwareFramesPerSecond];
}

- (void)recordFrameTime:(CFTimeInterval)frameTime
{
    ++self.frameNumber;
    _lastSecondOfFrameTimes[self.frameNumber % kHardwareFramesPerSecond] = frameTime;
}

- (void)clearLastSecondOfFrameTimes
{
    CFTimeInterval initialFrameTime = CACurrentMediaTime();
    for (NSInteger i = 0; i < kHardwareFramesPerSecond; ++i) {
        _lastSecondOfFrameTimes[i] = initialFrameTime;
    }
    self.frameNumber = 0;
}

- (void)updateMeterLabel
{
    self.meterLabel.text = [NSString stringWithFormat:@"%@", self.drawnFrameCountInLastSecond];
}

- (void)displayLinkWillDraw:(CADisplayLink *)displayLink
{
    CFTimeInterval currentFrameTime = displayLink.timestamp;

    [self recordFrameTime:currentFrameTime];

    [self updateMeterLabel];
}

#pragma mark -

- (void)start
{
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkWillDraw:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self clearLastSecondOfFrameTimes];
}

- (void)stop
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)setRunning:(BOOL)running
{
    if (_running != running) {
        if (running) {
            [self start];
        } else {
            [self stop];
        }

        _running = running;
    }
}

#pragma mark -

- (void)applicationDidBecomeActive
{
    self.running = self.enabled;
}

- (void)applicationWillResignActive
{
    self.running = NO;
}

#pragma mark -

- (void)enable
{
    CGFloat const kMeterWidth = 22.0;
    CGFloat xOrigin = ([UIScreen mainScreen].bounds.size.width - kMeterWidth) - 85;
    self.meterLabel= [[[UILabel alloc] initWithFrame:CGRectMake(xOrigin, 1, kMeterWidth, 15)] autorelease];
    self.meterLabel.font= [UIFont boldSystemFontOfSize:12];
    self.meterLabel.textAlignment=NSTextAlignmentCenter;
    self.meterLabel.userInteractionEnabled=NO;
    self.meterLabel.textColor = [UIColor whiteColor];
    self.meterLabel.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.6];
    self.meterLabel.layer.cornerRadius = 4;
    self.meterLabel.layer.masksToBounds = YES;
    [[UIApplication sharedApplication].keyWindow addSubview:self.meterLabel];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        self.running = YES;
    }
}

- (void)disable
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.running = NO;

    self.meterLabel = nil;
}

#pragma mark - Init/dealloc

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [_displayLink invalidate];

    self.displayLink = nil;
    self.meterLabel = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

#pragma mark - Public interface

+ (instancetype)sharedGeigerCounter
{
    static KMCGeigerCounter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [KMCGeigerCounter new];
    });
    return instance;
}

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        if (enabled) {
            [self enable];
        } else {
            [self disable];
        }

        _enabled = enabled;
    }
}

- (NSInteger)droppedFrameCountInLastSecond
{
    NSInteger droppedFrameCount = 0;

    CFTimeInterval lastFrameTime = CACurrentMediaTime() - kNormalFrameDuration;
    for (NSInteger i = 0; i < kHardwareFramesPerSecond; ++i) {
        if (1.0 <= lastFrameTime - _lastSecondOfFrameTimes[i]) {
            ++droppedFrameCount;
        }
    }

    return droppedFrameCount;
}

- (id)drawnFrameCountInLastSecond
{
    if (!self.running || self.frameNumber < kHardwareFramesPerSecond) {
        return @"--";
    }

    return [NSString stringWithFormat:@"%ld", kHardwareFramesPerSecond - self.droppedFrameCountInLastSecond];
}

@end
