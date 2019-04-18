/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RNStompWSModule.h"

#import <objc/runtime.h>

#import <React/RCTConvert.h>
#import <React/RCTUtils.h>

#import "RNCSRWebSocket.h"

@implementation RNCSRWebSocket (React)

- (NSNumber *)reactTag
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setReactTag:(NSNumber *)reactTag
{
    objc_setAssociatedObject(self, @selector(reactTag), reactTag, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@interface RNStompWSModule () <RNCSRWebSocketDelegate>

@end

@implementation RNStompWSModule
{
    NSMutableDictionary<NSNumber *, RNCSRWebSocket *> *_sockets;
    NSMutableDictionary<NSNumber *, id<RNStompWSContentHandler>> *_contentHandlers;
}

RCT_EXPORT_MODULE()

// Used by RCTBlobModule
@synthesize methodQueue = _methodQueue;

- (NSArray *)supportedEvents
{
    return @[@"stompWSMessage",
             @"stompWSOpen",
             @"stompWSFailed",
             @"stompWSClosed"];
}

- (void)invalidate
{
    _contentHandlers = nil;
    for (RNCSRWebSocket *socket in _sockets.allValues) {
        socket.delegate = nil;
        [socket close];
    }
}

RCT_EXPORT_METHOD(connect:(NSURL *)URL protocols:(NSArray *)protocols options:(NSDictionary *)options socketID:(nonnull NSNumber *)socketID)
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];

    // We load cookies from sharedHTTPCookieStorage (shared with XHR and
    // fetch). To get secure cookies for wss URLs, replace wss with https
    // in the URL.
    NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:true];
    if ([components.scheme.lowercaseString isEqualToString:@"wss"]) {
        components.scheme = @"https";
    }

    // Load and set the cookie header.
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:components.URL];
    request.allHTTPHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];

    // Load supplied headers
    [options[@"headers"] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        [request addValue:[RCTConvert NSString:value] forHTTPHeaderField:key];
    }];

    RNCSRWebSocket *webSocket = [[RNCSRWebSocket alloc] initWithURLRequest:request protocols:protocols];
    [webSocket setDelegateDispatchQueue:_methodQueue];
    webSocket.delegate = self;
    webSocket.reactTag = socketID;
    if (!_sockets) {
        _sockets = [NSMutableDictionary new];
    }
    _sockets[socketID] = webSocket;
    [webSocket open];
}

RCT_EXPORT_METHOD(send:(NSString *)message forSocketID:(nonnull NSNumber *)socketID)
{
    [_sockets[socketID] send: [message stringByReplacingOccurrencesOfString: @"^@" withString: @"\0" ]];
}

RCT_EXPORT_METHOD(sendBinary:(NSString *)base64String forSocketID:(nonnull NSNumber *)socketID)
{
    NSLog(@"sendData %@", base64String);
    [self sendData:[[NSData alloc] initWithBase64EncodedString:base64String options:0] forSocketID:socketID];
}

- (void)sendData:(NSData *)data forSocketID:(nonnull NSNumber *)socketID
{
    [_sockets[socketID] send:data];
}

RCT_EXPORT_METHOD(ping:(nonnull NSNumber *)socketID)
{
    [_sockets[socketID] sendPing:NULL];
}

RCT_EXPORT_METHOD(close:(nonnull NSNumber *)socketID)
{
    [_sockets[socketID] close];
    [_sockets removeObjectForKey:socketID];
}

- (void)setContentHandler:(id<RNStompWSContentHandler>)handler forSocketID:(NSString *)socketID
{
    if (!_contentHandlers) {
        _contentHandlers = [NSMutableDictionary new];
    }
    _contentHandlers[socketID] = handler;
}

#pragma mark - RNCSRWebSocketDelegate methods

- (void)webSocket:(RNCSRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSString *type;

    NSNumber *socketID = [webSocket reactTag];
    id contentHandler = _contentHandlers[socketID];
    if (contentHandler) {
        message = [contentHandler processWebsocketMessage:message forSocketID:socketID withType:&type];
    } else {
        if ([message isKindOfClass:[NSData class]]) {
            type = @"binary";
            message = [message base64EncodedStringWithOptions:0];
        } else {
            type = @"text";
        }
    }

    [self sendEventWithName:@"stompWSMessage" body:@{
                                                       @"data": message,
                                                       @"type": type,
                                                       @"id": webSocket.reactTag
                                                       }];
}

- (void)webSocketDidOpen:(RNCSRWebSocket *)webSocket
{
    [self sendEventWithName:@"stompWSOpen" body:@{
                                                    @"id": webSocket.reactTag
                                                    }];
}

- (void)webSocket:(RNCSRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSNumber *socketID = [webSocket reactTag];
    _contentHandlers[socketID] = nil;
    _sockets[socketID] = nil;
    [self sendEventWithName:@"stompWSFailed" body:@{
                                                      @"message": error.localizedDescription,
                                                      @"id": socketID
                                                      }];
}

- (void)webSocket:(RNCSRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean
{
    NSNumber *socketID = [webSocket reactTag];
    _contentHandlers[socketID] = nil;
    _sockets[socketID] = nil;
    [self sendEventWithName:@"stompWSClosed" body:@{
                                                      @"code": @(code),
                                                      @"reason": RCTNullIfNil(reason),
                                                      @"clean": @(wasClean),
                                                      @"id": socketID
                                                      }];
}

@end

@implementation RCTBridge (RNStompWSModule)

- (RNStompWSModule *)webSocketModule
{
    return [self moduleForClass:[RNStompWSModule class]];
}

@end
