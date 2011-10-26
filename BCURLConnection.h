#import <Foundation/Foundation.h>

@interface BCURLConnection : NSURLConnection

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

@end
