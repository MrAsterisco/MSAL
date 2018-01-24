//
//  MSALWebViewController.m
//  MSAL (iOS Framework)
//
//  Created by Alessio Moiso on 24/01/2018.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import "MSALWebViewController.h"

@interface MSALWebViewController ()

@end

@implementation MSALWebViewController
{
	NSURL *_url;
}

- (instancetype)initWithURL:(NSURL *)url {
	if (self = [super init]) {
		self->_url = url;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.navigationItem.title = @"Pillo";
}

@end
