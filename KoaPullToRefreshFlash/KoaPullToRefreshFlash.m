//
//  KoaPullToRefreshFlash.m
//  KoaPullToRefreshFlash
//
//  Created by Sergi Gracia on 09/05/13.
//  Copyright (c) 2013 Sergi Gracia. All rights reserved.
//

#import "KoaPullToRefreshFlash.h"
#import <QuartzCore/QuartzCore.h>

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat KoaPullToRefreshFlashViewHeight = 60;
static CGFloat KoaPullToRefreshFlashViewHeightShowed = 0;
static CGFloat KoaPullToRefreshFlashViewTitleBottomMargin = 12;

@interface KoaPullToRefreshFlashView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property(nonatomic, assign) BOOL isObserving;
@property(nonatomic, assign) BOOL releaseComplete;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end

#pragma mark - UIScrollView (KoaPullToRefreshFlash)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (KoaPullToRefreshFlash)
@dynamic pullToRefreshView, showsPullToRefresh;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    [self addPullToRefreshWithActionHandler:actionHandler withBackgroundColor:[UIColor grayColor]];
}

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                  withBackgroundColor:(UIColor *)customBackgroundColor {
    [self addPullToRefreshWithActionHandler:actionHandler withBackgroundColor:customBackgroundColor withPullToRefreshHeightShowed:KoaPullToRefreshFlashViewHeightShowed];
}

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                      withBackgroundColor:(UIColor *)customBackgroundColor
            withPullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed {
    
    //KoaPullToRefreshFlashViewHeight = pullToRefreshHeight;
    KoaPullToRefreshFlashViewHeightShowed = pullToRefreshHeightShowed;
    KoaPullToRefreshFlashViewTitleBottomMargin += pullToRefreshHeightShowed;
    
    [self setContentInset:UIEdgeInsetsMake(KoaPullToRefreshFlashViewHeightShowed, self.contentInset.left, self.contentInset.bottom, self.contentInset.right)];
    
    if (!self.pullToRefreshView) {
        
        //Initial y position
        CGFloat yOrigin = -KoaPullToRefreshFlashViewHeight;
        
        //Put background extra to fill top white space
        UIView *backgroundExtra = [[UIView alloc] initWithFrame:CGRectMake(0, -KoaPullToRefreshFlashViewHeight*8, self.bounds.size.width, KoaPullToRefreshFlashViewHeight*8)];
        [backgroundExtra setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [backgroundExtra setBackgroundColor:customBackgroundColor];
        [self addSubview:backgroundExtra];
        
        //Init pull to refresh view
        KoaPullToRefreshFlashView *view = [[KoaPullToRefreshFlashView alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, KoaPullToRefreshFlashViewHeight + KoaPullToRefreshFlashViewHeightShowed)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        view.backgroundColor = customBackgroundColor;
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        view.originalBottomInset = self.contentInset.bottom;
        
        self.pullToRefreshView = view;
        self.showsPullToRefresh = YES;
    }
}

- (void)setPullToRefreshView:(KoaPullToRefreshFlashView *)pullToRefreshView {
    [self willChangeValueForKey:@"KoaPullToRefreshFlashView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"KoaPullToRefreshFlashView"];
}

- (KoaPullToRefreshFlashView *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    self.pullToRefreshView.hidden = !showsPullToRefresh;
    
    if(!showsPullToRefresh) {
        if (self.pullToRefreshView.isObserving) {
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
            [self.pullToRefreshView resetScrollViewContentInset];
            self.pullToRefreshView.isObserving = NO;
        }
    }else {
        if (!self.pullToRefreshView.isObserving) {
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.pullToRefreshView.isObserving = YES;
            
            CGFloat yOrigin = -KoaPullToRefreshFlashViewHeight;
            self.pullToRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, KoaPullToRefreshFlashViewHeight + KoaPullToRefreshFlashViewHeightShowed);
        }
    }
}

- (BOOL)showsPullToRefresh {
    return !self.pullToRefreshView.hidden;
}

@end


#pragma mark - KoaPullToRefreshFlash
@implementation KoaPullToRefreshFlashView

@synthesize pullToRefreshActionHandler, textColor, textFont;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize titleLabel = _titleLabel;

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.textColor = [UIColor darkGrayColor];
        self.backgroundColor = [UIColor whiteColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
        
        self.title = NSLocalizedString(@"Release now", nil);
        
        self.wasTriggeredByUser = YES;
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "KoaPullToRefreshFlashView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews
{
    CGFloat leftViewWidth = 60;
    CGFloat margin = 10;
    CGFloat labelMaxWidth = self.bounds.size.width - margin - leftViewWidth;
    
    //Set title text
    self.titleLabel.text = self.title;
    
    //Set title frame
    CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(labelMaxWidth,self.titleLabel.font.lineHeight) lineBreakMode:self.titleLabel.lineBreakMode];
    CGFloat titleY = KoaPullToRefreshFlashViewHeight/2 - titleSize.height/2;
    
    [self.titleLabel setFrame:CGRectIntegral(CGRectMake(0, titleY, self.frame.size.width, titleSize.height))];
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset + self.bounds.size.height;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        
        CGFloat yOrigin;
        yOrigin = -KoaPullToRefreshFlashViewHeight;
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, KoaPullToRefreshFlashViewHeight);
    }
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    
    //Change title label alpha
    if (contentOffset.y < -(KoaPullToRefreshFlashViewHeight/2)) {
        CGFloat alpha = abs(contentOffset.y + (KoaPullToRefreshFlashViewHeight/2)) / (KoaPullToRefreshFlashViewHeight/2);
        [self.titleLabel setAlpha: alpha];
    }else{
        [self.titleLabel setAlpha: 0];
    }
    
    if (self.scrollView.contentOffset.y == -KoaPullToRefreshFlashViewHeightShowed) {
        self.releaseComplete = NO;
    }else if (self.scrollView.contentOffset.y <= -KoaPullToRefreshFlashViewHeight){
        if (!self.releaseComplete) {
            pullToRefreshActionHandler();
            self.releaseComplete = YES;
        }
    }
}


#pragma mark - Getters

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _titleLabel.text = NSLocalizedString(@"Pull",);
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = textColor;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UIColor *)textColor {
    return self.titleLabel.textColor;
}

- (UIFont *)textFont {
    return self.titleLabel.font;
}

#pragma mark - Setters

- (void)setMessage:(NSString *)message {
    if(!message)
        message = @"";
    
    self.title = message;
    
    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    self.titleLabel.textColor = newTextColor;
}

- (void)setTextFont:(UIFont *)font
{
    [self.titleLabel setFont:font];
}

@end
