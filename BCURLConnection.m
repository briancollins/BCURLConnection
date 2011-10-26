#import <objc/runtime.h>

#import "BCURLConnection.h"

typedef void (^BCCallbackBlock)(NSURLResponse*, NSData*, NSError*);

@interface BCURLConnectionHandler : NSObject <NSURLConnectionDelegate>

@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) BCCallbackBlock handler;
@property (strong, nonatomic) NSOperationQueue *queue;
@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSURLResponse *response;

@end

@implementation BCURLConnectionHandler
@synthesize connection, handler = _handler, queue = _queue, data = _data, response = _response;

- (void)performRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    self.handler = handler;
    
    if (!queue) queue = [NSOperationQueue mainQueue];
    self.queue = queue;
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    BCCallbackBlock handler = self.handler;
    self.handler = nil;
    
    NSURLResponse *response = self.response;
    [self.queue addOperationWithBlock:^{
        handler(response, nil, error);
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (response.expectedContentLength > 0) {
        self.data = [NSMutableData dataWithCapacity:response.expectedContentLength];
    } else {
        self.data = [NSMutableData data];
    }
    
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    BCCallbackBlock handler = self.handler;
    self.handler = nil;
    
    NSURLResponse *response = self.response;
    NSData *data = [self.data copy];
    
    [self.queue addOperationWithBlock:^{
        handler(response, data, nil);
    }];
}

@end

@implementation BCURLConnection

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    
    if (class_getClassMethod([self superclass], @selector(sendAsynchronousRequest:queue:completionHandler:)) != NULL) {
        [super sendAsynchronousRequest:request queue:queue completionHandler:handler];
    } else {
        BCURLConnectionHandler *connectionHandler = [[BCURLConnectionHandler alloc] init];
        [connectionHandler performRequest:request queue:queue completionHandler:handler];
    }
}

@end
