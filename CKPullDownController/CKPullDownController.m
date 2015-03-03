//
//  CKPullDownController.m
//  CKPullDownController
//
//  Created by Matej Bukovinski on 22. 02. 13.
//  Copyright (c) 2013 Matej Bukovinski. All rights reserved.
//

#import "CKPullDownController.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

#define IOS_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static CGFloat const kDefaultClosedTopOffset = 44.f;
static CGFloat const kDefaultOpenBottomOffset = 44.f;
static CGFloat const kDefaultOpenDragOffset = NAN;
static CGFloat const kDefaultCloseDragOffset = NAN;
static CGFloat const kDefaultOpenDragOffsetPercentage = .2;
static CGFloat const kDefaultCloseDragOffsetPercentage = .05;

@interface CKPullDownControllerTapUpRecognizer : UITapGestureRecognizer

@property BOOL dragged;

@end

@interface CKScrollView : UIScrollView

@property(nonatomic, strong) UIViewController *viewController;

@end

@implementation CKScrollView

- (instancetype)initWithFrontViewController:(UIViewController *)viewController
{
	self = [super init];
	if (self) {
		self.delaysContentTouches = NO;
		self.viewController = viewController;
	}

	return self;
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView *result = nil;
	UIView *frontView = self.viewController.view.subviews.lastObject;
	for (UIView *child in frontView.subviews) {
		CGPoint pointChild = [child convertPoint:point fromView:self];
		if (child.userInteractionEnabled && [child pointInside:pointChild withEvent:event]) {
			if ((result = [child hitTest:pointChild withEvent:event]) != nil) {
				break;
			}
		}
	}
	if (result) {
		return result;
	}
	return [super hitTest:point withEvent:event];
}

@end

@interface CKPullDownControllerContainerView : UIView

@property(nonatomic, weak) CKPullDownController *pullDownController;

@end

@interface CKScrollViewController : UIViewController <UIScrollViewDelegate>
@end

@implementation CKScrollViewController
- (instancetype)initWithFrontViewController:(UIViewController *)frontViewController
{
	self = [super init];
	if (self) {
		self.view = [[CKScrollView alloc] initWithFrontViewController:frontViewController];
	}

	return self;
}

@end

@interface CKPullDownController ()

@property(nonatomic, strong) CKPullDownControllerTapUpRecognizer *tapUpRecognizer;
@property(nonatomic, assign) BOOL adjustedScroll;
@property(nonatomic, strong) CKScrollViewController *scrollViewController;

@end

@implementation CKPullDownController

#pragma mark - Lifecycle


- (id)init
{
	return [self initWithFrontController:nil backController:nil];
}


- (id)initWithFrontController:(UIViewController *)front backController:(UIViewController *)back
{
	self = [super init];
	if (self) {
		_scrollViewController = [[CKScrollViewController alloc] initWithFrontViewController:front];
		_frontController = front;
		_backController = back;
		[self sharedInitialization];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self sharedInitialization];
	}
	return self;
}


- (void)sharedInitialization
{
	_pullToToggleEnabled = YES;
	_closedTopOffset = kDefaultClosedTopOffset;
	_openBottomOffset = kDefaultOpenBottomOffset;
	_openDragOffset = kDefaultOpenDragOffset;
	_closeDragOffset = kDefaultCloseDragOffset;
	_openDragOffsetPercentage = kDefaultOpenDragOffsetPercentage;
	_closeDragOffsetPercentage = kDefaultCloseDragOffsetPercentage;
	_backgroundView = _frontController.view;
	[self addChildViewController:_frontController];
}


- (void)loadView
{
	CGRect frame = [UIScreen mainScreen].bounds;
	CKPullDownControllerContainerView *view = [[CKPullDownControllerContainerView alloc] initWithFrame:frame];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.pullDownController = self;
	self.view = view;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	[self changeBackControllerFrom:nil to:self.backController];
	[self changeFrontControllerFrom:nil to:self.scrollViewController];
}


/**
* Fixes the bottom bar when the call status bar is displayed
* //TODO make it work for the app open with the call status bar is already displayed
*/
- (void)viewDidLayoutSubviews
{
	if (IOS_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
		[UIView animateWithDuration:.35 animations:^{
			if (self.open) {
				[self setOpen:self.open animated:NO];
			}
		}];
	}
	[super viewDidLayoutSubviews];
}


- (void)dealloc
{
	[self cleanUpScrollView:[self scrollView]];
}


#pragma mark - ScrollView Delegate


- (void)setScrollViewDelegate:(id <UIScrollViewDelegate>)delegate
{
	((UIScrollView *) self.scrollViewController.view).delegate = delegate;
}


#pragma mark - Layout


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self setOpen:self.open animated:NO];
}


#pragma mark - Status bar


- (UIViewController *)childViewControllerForStatusBarHidden
{
	return self.scrollViewController;
}


- (UIViewController *)childViewControllerForStatusBarStyle
{
	return self.scrollViewController;
}


#pragma mark - Controllers


- (void)setScrollViewController:(UIViewController *)scrollViewController
{
	if (_scrollViewController != scrollViewController) {
		UIViewController *oldController = _scrollViewController;
		_scrollViewController = (CKScrollViewController *) scrollViewController;
		if (self.isViewLoaded) {
			[self changeFrontControllerFrom:oldController to:scrollViewController];
		}
	}
}


- (void)setBackController:(UIViewController *)backController
{
	if (_backController != backController) {
		UIViewController *oldController = _backController;
		_backController = backController;
		if (self.isViewLoaded) {
			[self changeBackControllerFrom:oldController to:backController];
		}
	}
}


#pragma mark - Offsets


- (void)setClosedTopOffset:(CGFloat)closedTopOffset
{
	[self setClosedTopOffset:closedTopOffset animated:NO];
}


- (void)setClosedTopOffset:(CGFloat)closedTopOffset animated:(BOOL)animated
{
	if (_closedTopOffset != closedTopOffset) {
		_closedTopOffset = closedTopOffset;
		if (!self.open) {
			[self setOpen:NO animated:animated];
		}
	}
}


- (void)setOpenBottomOffset:(CGFloat)openBottomOffset
{
	[self setOpenBottomOffset:openBottomOffset animated:NO];
}


- (void)setOpenBottomOffset:(CGFloat)openBottomOffset animated:(BOOL)animated
{
	if (_openBottomOffset != openBottomOffset) {
		_openBottomOffset = openBottomOffset;
		if (self.open) {
			[self setOpen:YES animated:animated];
		}
	}
}


- (void)setOpenDragOffsetPercentage:(CGFloat)openDragOffsetPercentage
{
	NSAssert(openDragOffsetPercentage >= 0.f && openDragOffsetPercentage <= 1.f,
			@"openDragOffsetPercentage out of bounds [0.f, 1.f]");
	_openDragOffsetPercentage = openDragOffsetPercentage;
}


- (void)setCloseDragOffsetPercentage:(CGFloat)closeDragOffsetPercentage
{
	NSAssert(closeDragOffsetPercentage >= 0.f && closeDragOffsetPercentage <= 1.f,
			@"closeDragOffsetPercentage out of bounds [0.f, 1.f]");
	_closeDragOffsetPercentage = closeDragOffsetPercentage;
}


- (CGFloat)computedOpenDragOffset
{
	if (!isnan(_openDragOffset)) {
		return _openDragOffset;
	}
	return _openDragOffsetPercentage * self.view.bounds.size.height;
}


- (CGFloat)computedCloseDragOffset
{
	if (!isnan(_closeDragOffset)) {
		return _closeDragOffset;
	}
	return _closeDragOffsetPercentage * self.view.bounds.size.height;
}


#pragma mark - Open / close actions


- (void)toggleOpenAnimated:(BOOL)animated
{
	[self setOpen:!_open animated:animated];
}


- (void)setOpen:(BOOL)open
{
	[self setOpen:open animated:NO];
}


- (void)setOpen:(BOOL)open animated:(BOOL)animated
{
	if (open != _open) {
		[self willChangeValueForKey:@"open"];
		_open = open;
		[self didChangeValueForKey:@"open"];
	}

	UIScrollView *scrollView = [self scrollView];
	if (!scrollView) {
		return;
	}

	CGFloat offset = open ? self.view.bounds.size.height - self.openBottomOffset : self.closedTopOffset;
	CGPoint sOffset = scrollView.contentOffset;
	// Set content inset (no animation)
	UIEdgeInsets contentInset = scrollView.contentInset;
	contentInset.top = offset;
	scrollView.contentInset = contentInset;
	// Restor the previous scroll offset, sicne the contentInset change coud had changed it
	[scrollView setContentOffset:sOffset];

	// Update the scroll indicator insets
	void (^updateScrollInsets)(void) = ^{
		UIEdgeInsets scrollIndicatorInsets = scrollView.scrollIndicatorInsets;
		scrollIndicatorInsets.top = offset;
		scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
	};
	if (animated) {
		[UIView animateWithDuration:.25f animations:updateScrollInsets];
	} else {
		updateScrollInsets();
	}

	// Move the content
	if (animated) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[scrollView setContentOffset:CGPointMake(0.f, -offset) animated:YES];
		});
	} else {
		[scrollView setContentOffset:CGPointMake(0.f, -offset)];
	}
}


#pragma mark - Container controller


- (void)changeFrontControllerFrom:(UIViewController *)current to:(UIViewController *)new
{

	[current removeFromParentViewController];
	[self cleanUpScrollView:(UIScrollView *) current.view];
	[current.view removeFromSuperview];

	if (new) {
		[self addChildViewController:new];
		UIView *containerView = self.view;
		UIView *newView = new.view;
		NSAssert(!newView || [newView isKindOfClass:[UIScrollView class]],
				@"The front controller's view is not a UIScrollView subclass.");
		if (newView) {
			newView.frame = containerView.bounds;
			[containerView addSubview:newView];
			[new didMoveToParentViewController:self];
		}
	}

	[self prepareScrollView:(UIScrollView *) new.view];
	[self setOpen:self.open animated:NO];
}


- (void)changeBackControllerFrom:(UIViewController *)current to:(UIViewController *)new
{

	[current removeFromParentViewController];
	[current.view removeFromSuperview];

	if (new) {
		[self addChildViewController:new];
		UIView *containerView = self.view;
		UIView *newView = new.view;
		if (newView) {
			newView.frame = containerView.bounds;
			[containerView insertSubview:newView atIndex:0];
			[new didMoveToParentViewController:self];
		}
	}
}


#pragma mark - BacgroundView


- (void)setBackgroundView:(UIView *)backgroundView
{
	[_backgroundView removeFromSuperview];
	_backgroundView = backgroundView;
	[self initializeBackgroundView];
}


- (void)initializeBackgroundView
{
	UIView *containerView = self.view;
	UIView *backgroundView = self.backgroundView;
	UIScrollView *scrollView = [self scrollView];
	if (scrollView && backgroundView) {
		backgroundView.frame = containerView.bounds;
		[containerView insertSubview:backgroundView belowSubview:scrollView];
		[self updateBackgroundViewForScrollOfset:scrollView.contentOffset];
	}
}


- (void)updateBackgroundViewForScrollOfset:(CGPoint)offset
{
	CGRect frame = self.backgroundView.frame;
	frame.origin.y = MAX(0.f, -offset.y);
	self.backgroundView.frame = frame;
}


#pragma mark - ScrollView


- (UIScrollView *)scrollView
{
	return (UIScrollView *) self.scrollViewController.view;
}


- (void)prepareScrollView:(UIScrollView *)scrollView
{
	if (scrollView) {
		scrollView.backgroundColor = [UIColor clearColor];
		scrollView.alwaysBounceVertical = YES;
		[self registerForScrollViewKVO:scrollView];
		[self addGestureRecognizersToScrollView:scrollView];
		[self initializeBackgroundView];
	}
}


- (void)cleanUpScrollView:(UIScrollView *)scrollView
{
	if (scrollView) {
		[self unregisterFromScrollViewKVO:scrollView];
		[self.backgroundView removeFromSuperview];
		[self removeGesureRecognizersFromScrollView:scrollView];
	}
}


- (void)checkOpenCloseConstraints
{
	BOOL open = self.open;
	BOOL enabled = self.pullToToggleEnabled;
	CGPoint offset = [self scrollView].contentOffset;
	if (!open && enabled && offset.y < -[self computedOpenDragOffset] - self.closedTopOffset) {
		[self setOpen:YES animated:YES];
	} else if (open) {
		[self setOpen:!(enabled && offset.y > [self computedCloseDragOffset] - self.view.bounds.size.height + self.openBottomOffset) animated:YES];
	}
}


#pragma mark - Gestures


- (void)addGestureRecognizersToScrollView:(UIScrollView *)scrollView
{
	CKPullDownControllerTapUpRecognizer *tapUp;
	tapUp = [[CKPullDownControllerTapUpRecognizer alloc] initWithTarget:self action:@selector(tapUp:)];
	[scrollView addGestureRecognizer:tapUp];
	self.tapUpRecognizer = tapUp;
}


- (void)removeGesureRecognizersFromScrollView:(UIScrollView *)scrollView
{
	[scrollView removeGestureRecognizer:self.tapUpRecognizer];
}


- (void)tapUp:(CKPullDownControllerTapUpRecognizer *)recognizer
{
	[self checkOpenCloseConstraints];
	if (self.pullDownController.open && !self.tapUpRecognizer.dragged) {
		//fakes a drag so the delegate can handle clicks
		[self.scrollView.delegate scrollViewWillBeginDragging:self.scrollView];
		[self setOpen:NO animated:YES];
	}
}


#pragma mark - KVO


- (void)registerForScrollViewKVO:(UIScrollView *)scrollView
{
	self.adjustedScroll = NO;
	[scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}


- (void)unregisterFromScrollViewKVO:(UIScrollView *)scrollView
{
	[scrollView removeObserver:self forKeyPath:@"contentOffset"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"contentOffset"]) {
		UIScrollView *scrollView = object;
		if (!self.adjustedScroll) {
			CGPoint oldValue = [[change valueForKey:NSKeyValueChangeOldKey] CGPointValue];
			CGPoint newValue = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
			CGPoint adjusted = newValue;
			// Hide the scroll indicator while dragging
			scrollView.showsVerticalScrollIndicator = !(!scrollView.decelerating && (self.open || newValue.y < -self.closedTopOffset));
			// Simulate the scroll view elasticity effect while dragging in the open state
			if (self.open && [self scrollView].dragging) {
				CGFloat delta = (oldValue.y - newValue.y);
				adjusted = CGPointMake(newValue.x, oldValue.y - delta);
				self.adjustedScroll = YES; // prevent infinite recursion
				scrollView.contentOffset = adjusted;
			}
			[self updateBackgroundViewForScrollOfset:adjusted];
		} else {
			self.adjustedScroll = NO;
		}
	}
}

@end

@implementation UIViewController (MBPullDownController)

- (CKPullDownController *)pullDownController
{
	UIViewController *controller = self;
	while (controller != nil) {
		if ([controller isKindOfClass:[CKPullDownController class]]) {
			return (CKPullDownController *) controller;
		}
		controller = controller.parentViewController;
	}
	return nil;
}

@end

@implementation CKPullDownControllerTapUpRecognizer

#pragma mark - Lifecycle


- (id)initWithTarget:(id)target action:(SEL)action
{
	self = [super initWithTarget:target action:action];
	if (self) {
		self.cancelsTouchesInView = NO;
		self.delaysTouchesBegan = NO;
		self.delaysTouchesEnded = NO;
	}
	return self;
}


#pragma mark - Touch handling


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.dragged = NO;
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.dragged = YES;
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.state = UIGestureRecognizerStateRecognized;
	self.state = UIGestureRecognizerStateEnded;
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.state = UIGestureRecognizerStateRecognized;
	self.state = UIGestureRecognizerStateEnded;
}


#pragma mark - Tap prevention


- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
	return NO;
}


- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
	return NO;
}

@end


@implementation CKPullDownControllerContainerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIScrollView *scrollView = [self.pullDownController scrollView];
	if (scrollView) {
		CGPoint pointInScrollView = [scrollView convertPoint:point fromView:self];
		if (pointInScrollView.y <= 0.f) {
			UIView *targetView = self.pullDownController.backController.view;
			return [targetView hitTest:[self convertPoint:point toView:targetView] withEvent:event];
		}
	}
	return [super hitTest:point withEvent:event];
}

@end
