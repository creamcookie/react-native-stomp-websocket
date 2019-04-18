//
//   Copyright 2012 Square Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import <Foundation/Foundation.h>
#import <Security/SecCertificate.h>

typedef NS_ENUM(unsigned int, RNCSRReadyState) {
    RNCSR_CONNECTING   = 0,
    RNCSR_OPEN         = 1,
    RNCSR_CLOSING      = 2,
    RNCSR_CLOSED       = 3,
};

typedef NS_ENUM(NSInteger, RNCSRStatusCode) {
    RNCSRStatusCodeNormal = 1000,
    RNCSRStatusCodeGoingAway = 1001,
    RNCSRStatusCodeProtocolError = 1002,
    RNCSRStatusCodeUnhandledType = 1003,
    // 1004 reserved.
    RNCSRStatusNoStatusReceived = 1005,
    // 1004-1006 reserved.
    RNCSRStatusCodeInvalidUTF8 = 1007,
    RNCSRStatusCodePolicyViolated = 1008,
    RNCSRStatusCodeMessageTooBig = 1009,
};

@class RNCSRWebSocket;

extern NSString *const RNCSRWebSocketErrorDomain;
extern NSString *const RNCSRHTTPResponseErrorKey;

#pragma mark - RNCSRWebSocketDelegate

@protocol RNCSRWebSocketDelegate;

#pragma mark - RNCSRWebSocket

@interface RNCSRWebSocket : NSObject <NSStreamDelegate>

@property (nonatomic, weak) id<RNCSRWebSocketDelegate> delegate;

@property (nonatomic, readonly) RNCSRReadyState readyState;
@property (nonatomic, readonly, strong) NSURL *url;

// This returns the negotiated protocol.
// It will be nil until after the handshake completes.
@property (nonatomic, readonly, copy) NSString *protocol;

// Protocols should be an array of strings that turn into Sec-WebSocket-Protocol.
- (instancetype)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray<NSString *> *)protocols NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithURLRequest:(NSURLRequest *)request;

// Some helper constructors.
- (instancetype)initWithURL:(NSURL *)url protocols:(NSArray<NSString *> *)protocols;
- (instancetype)initWithURL:(NSURL *)url;

// Delegate queue will be dispatch_main_queue by default.
// You cannot set both OperationQueue and dispatch_queue.
- (void)setDelegateOperationQueue:(NSOperationQueue *)queue;
- (void)setDelegateDispatchQueue:(dispatch_queue_t)queue;

// By default, it will schedule itself on +[NSRunLoop RNCSR_networkRunLoop] using defaultModes.
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
- (void)unscheduleFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;

// RNCSRWebSockets are intended for one-time-use only.  Open should be called once and only once.
- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

// Send Data (can be nil) in a ping message.
- (void)sendPing:(NSData *)data;

@end

#pragma mark - RNCSRWebSocketDelegate

@protocol RNCSRWebSocketDelegate <NSObject>

// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(RNCSRWebSocket *)webSocket didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(RNCSRWebSocket *)webSocket;
- (void)webSocket:(RNCSRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(RNCSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
- (void)webSocket:(RNCSRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;

@end

#pragma mark - NSURLRequest (CertificateAdditions)

@interface NSURLRequest (CertificateAdditions)

@property (nonatomic, readonly, copy) NSArray *RNCSR_SSLPinnedCertificates;

@end

#pragma mark - NSMutableURLRequest (CertificateAdditions)

@interface NSMutableURLRequest (CertificateAdditions)

@property (nonatomic, copy) NSArray *RNCSR_SSLPinnedCertificates;

@end

#pragma mark - NSRunLoop (RNCSRWebSocket)

@interface NSRunLoop (RNCSRWebSocket)

+ (NSRunLoop *)RNCSR_networkRunLoop;

@end
