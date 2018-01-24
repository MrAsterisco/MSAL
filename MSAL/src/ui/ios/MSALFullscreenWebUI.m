//
//  MSALFullscreenWebUI.m
//  MSAL (iOS Framework)
//
//  Created by Alessio Moiso on 24/01/2018.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

#import "MSALFullscreenWebUI.h"
#import "MSALWebViewController.h"
#import "UIApplication+MSALExtensions.h"
#import "MSALTelemetry.h"
#import "MSALTelemetry+Internal.h"
#import "MSALTelemetryUIEvent.h"
#import "MSALTelemetryEventStrings.h"

static MSALFullscreenWebUI *s_currentWebSession = nil;

@interface MSALFullscreenWebUI () <MSALWebViewControllerDelegate>

@end

@implementation MSALFullscreenWebUI
{
	NSURL *_url;
	UINavigationController *_navigationController;
	MSALWebViewController *_controller;
	MSALWebUICompletionBlock _completionBlock;
	id<MSALRequestContext> _context;
	NSString *_telemetryRequestId;
	MSALTelemetryUIEvent *_telemetryEvent;
}

+ (void)startWebUIWithURL:(NSURL *)url
				  context:(id<MSALRequestContext>)context
		  completionBlock:(MSALWebUICompletionBlock)completionBlock
{
	CHECK_ERROR_COMPLETION(url, context, MSALErrorInternal, @"Attempted to start WebUI with nil URL");

	MSALFullscreenWebUI *webUI = [MSALFullscreenWebUI new];
	webUI->_context = context;
	[webUI startWithURL:url completionBlock:completionBlock];
}

+ (MSALFullscreenWebUI *)getAndClearCurrentWebSession
{
	MSALFullscreenWebUI *webSession = nil;
	@synchronized ([MSALFullscreenWebUI class])
	{
		webSession = s_currentWebSession;
		s_currentWebSession = nil;
	}

	return webSession;
}

+ (BOOL)cancelCurrentWebAuthSession
{
	MSALFullscreenWebUI *webSession = [MSALFullscreenWebUI getAndClearCurrentWebSession];
	if (!webSession)
	{
		return NO;
	}
	[webSession cancel];
	return YES;
}

- (BOOL)clearCurrentWebSession
{
	@synchronized ([MSALFullscreenWebUI class])
	{
		if (s_currentWebSession != self)
		{
			// There's no error param because this isn't on a critical path. If we're seeing this error there is
			// a developer error somewhere in the code, but that won't necessarily prevent MSAL from otherwise
			// working.
			LOG_ERROR(_context, @"Trying to clear out someone else's session");
			return NO;
		}

		s_currentWebSession = nil;
		return YES;
	}
}

- (void)cancel
{
	[_telemetryEvent setIsCancelled:YES];
	[self completeSessionWithResponse:nil orError:CREATE_LOG_ERROR(_context, MSALErrorSessionCanceled, @"Authorization session was cancelled programatically")];
}

- (void)startWithURL:(NSURL *)url
	 completionBlock:(MSALWebUICompletionBlock)completionBlock
{
	@synchronized ([MSALFullscreenWebUI class])
	{
		CHECK_ERROR_COMPLETION((!s_currentWebSession), _context, MSALErrorInteractiveSessionAlreadyRunning, @"Only one interactive session is allowed at a time.");
		s_currentWebSession = self;
	}

	_telemetryRequestId = [_context telemetryRequestId];

	[[MSALTelemetry sharedInstance] startEvent:_telemetryRequestId eventName:MSAL_TELEMETRY_EVENT_UI_EVENT];
	_telemetryEvent = [[MSALTelemetryUIEvent alloc] initWithName:MSAL_TELEMETRY_EVENT_UI_EVENT
														 context:_context];

	[_telemetryEvent setIsCancelled:NO];

	dispatch_async(dispatch_get_main_queue(), ^{
		_controller = [[MSALWebViewController alloc] initWithURL:url];

		_controller.delegate = self;

		UIViewController *viewController = [UIApplication msalCurrentViewController];
		if (!viewController)
		{
			[self clearCurrentWebSession];
			ERROR_COMPLETION(_context, MSALErrorNoViewController, @"MSAL was unable to find the current view controller.");
		}

		_navigationController = [[UINavigationController alloc] initWithRootViewController:_controller];

		[viewController presentViewController:_navigationController animated:YES completion:nil];

		@synchronized (self)
		{
			_completionBlock = completionBlock;
		}
	});
}

- (void)webViewControllerDidFinish:(MSALWebViewController *)controller {
	(void)controller;
	if (![self clearCurrentWebSession])
	{
		return;
	}

	[_telemetryEvent setIsCancelled:YES];
	[self completeSessionWithResponse:nil orError:CREATE_LOG_ERROR(_context, MSALErrorUserCanceled, @"User cancelled the authorization session.")];
}

+ (BOOL)handleResponse:(NSURL *)url
{
	if (!url)
	{
		LOG_ERROR(nil, @"nil passed into MSAL Web handle response");
		return NO;
	}

	MSALFullscreenWebUI *webSession = [MSALFullscreenWebUI getAndClearCurrentWebSession];
	if (!webSession)
	{
		LOG_ERROR(nil, @"Received MSAL web response without a current session running.");
		return NO;
	}

	return [webSession completeSessionWithResponse:url orError:nil];
}

- (BOOL)completeSessionWithResponse:(NSURL *)response
							orError:(NSError *)error
{
	if ([NSThread isMainThread])
	{
		[_controller dismissViewControllerAnimated:YES completion:nil];
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[_controller dismissViewControllerAnimated:YES completion:nil];
		});
	}

	MSALWebUICompletionBlock completionBlock = nil;
	@synchronized (self)
	{
		completionBlock = _completionBlock;
		_completionBlock = nil;
	}

	_controller = nil;

	if (!completionBlock)
	{
		LOG_ERROR(_context, @"MSAL response received but no completion block saved");
		return NO;
	}

	[[MSALTelemetry sharedInstance] stopEvent:_telemetryRequestId event:_telemetryEvent];

	completionBlock(response, error);
	return YES;
}

@end
