//
//  MSALWebViewController.h
//  MSAL (iOS Framework)
//
//  Created by Alessio Moiso on 24/01/2018.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MSALWebViewControllerDelegate;

@interface MSALWebViewController : UIViewController

- (instancetype _Nonnull)initWithURL:(NSURL*_Nonnull)url;

@property (nonatomic, weak, nullable) id <MSALWebViewControllerDelegate> delegate;

@property (nonatomic, nullable) id<MSALRequestContext> parameters;

@end

@protocol MSALWebViewControllerDelegate <NSObject>

- (void)webViewControllerDidFinish:(MSALWebViewController *_Nonnull)controller;

@end
