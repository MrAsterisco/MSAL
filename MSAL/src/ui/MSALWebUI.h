//
//  MSALGenericWebUI.h
//  MSAL
//
//  Created by Alessio Moiso on 24/01/2018.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#ifndef MSALGenericWebUI_h
#define MSALGenericWebUI_h

typedef void (^MSALWebUICompletionBlock)(NSURL *response, NSError *error);

@protocol MSALWebUI

+ (void)startWebUIWithURL:(NSURL *)url
				  context:(id<MSALRequestContext>)context
		  completionBlock:(MSALWebUICompletionBlock)completionBlock;

+ (BOOL)handleResponse:(NSURL *)url;

+ (BOOL)cancelCurrentWebAuthSession;

@end

#endif /* MSALGenericWebUI_h */
