//
//  MongooseDaemon.m
//
//  Created by Rama McIntosh on 3/4/09.
//  Copyright Rama McIntosh 2009. All rights reserved.
//

//
// Copyright (c) 2009, Rama McIntosh All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
// * Redistributions of source code must retain the above copyright
//   notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
// * Neither the name of Rama McIntosh nor the names of its
//   contributors may be used to endorse or promote products derived
//   from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

#import "MongooseDaemon.h"
#import "MongooseDaemon_MongooseCallbacks.h"
#import "mongoose.h"
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>


//
// supported mongoose options
typedef NS_ENUM(NSUInteger, mongooseOptionIndex) {
  mongooseOptionIndexDocumentRoot = 0,
  mongooseOptionIndexListeningPort
};
const NSUInteger kNumberOfSupportedOptions = 2;

const char * kMongooseOptionDocumentRoot = "document_root";
const char * kMongooseOptionListeningPorts = "listening_ports";


@interface MongooseDaemon ()

@property (strong) dispatch_queue_t queue;

@end

@implementation MongooseDaemon {
  struct mg_context *_ctx;
  struct mg_callbacks _callbacks;
}

@synthesize documentRoot = _documentRoot;
@synthesize listeningPorts = _listeningPorts;

- (id)init {
  self = [super init];
  if (self) {
    // create a serial queue
    static int queueCount = 0;
    NSString *queueLabel = [NSString stringWithFormat:@"%@.MongooseQueue.%d", [[NSBundle mainBundle] bundleIdentifier], queueCount++];
    self.queue = dispatch_queue_create([queueLabel UTF8String], NULL);
    dispatch_sync(self.queue, ^{
      CIMLog(logMongoose, @"[%@] created queue [%@]", self, self.queue);
      
      // Prepare callbacks structure.
      memset(&_callbacks, 0, sizeof(_callbacks));
      _callbacks.begin_request = &begin_request;
      _callbacks.end_request = &end_request;
      _callbacks.log_message = &log_message;
      _callbacks.thread_start = &thread_start;
      _callbacks.thread_stop = &thread_stop;
      
      // list available options and their defaults
      const char **options = mg_get_valid_option_names();
      NSMutableDictionary *mongooseOptions = [NSMutableDictionary dictionary];
      int i;
      for (i = 0; options[i * 2] != NULL; i++) {
        NSString *option = [NSString stringWithUTF8String:options[i * 2]];
        if (options[i * 2 + 1] == NULL) {
          mongooseOptions[option] = [NSNull null];
        } else {
          mongooseOptions[option] = [NSString stringWithUTF8String:options[i * 2 + 1]];
        }
      }
      CIMLog(logMongoose, @"Mongoose Options = %@", mongooseOptions);
      
      // set port and root defaults
      _listeningPorts = @[@8080];
      _documentRoot = NSHomeDirectory();
      
    });
  }
  return self;
}

- (void)dealloc {
  [self stop];
  self.documentRoot = nil;
}


#pragma mark - start/stop

- (void)start {
  dispatch_sync(self.queue, ^{
    if (_ctx == NULL) {
      
      // List of options. Last element must be NULL.
      // TODO: dynamically generate this array based on set parameters
      //       ...or just set all options every time
      const char *options[[self numberOfSupportedOptions] * 2 + 1];
      NSUInteger i;
      for (i = 0; i < [self numberOfSupportedOptions]; i++) {
        options[i * 2] = [self nameOfOptionAtIndex:i];
        options[i * 2 + 1] = [self valueOfOptionAtIndex:i];
      }
      options[i * 2] = NULL;
      
      // start the web server
      _ctx = mg_start(&_callbacks, (__bridge void *)(self), options);     // Start Mongoose serving thread
    }
  });
}

- (void)stop {
  dispatch_sync(self.queue, ^{
    if (_ctx != NULL) {
      mg_stop(_ctx);
      _ctx = NULL;
    }
  });
}


#pragma mark - Public Properties

+ (NSString *)versionString {
  return [NSString stringWithFormat:@"%@.%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

+ (NSString *)mongooseVersionString {
  return [NSString stringWithUTF8String:mg_version()];
}

- (BOOL)isRunning {
  __block BOOL running;
  dispatch_sync(self.queue, ^{
    running = (_ctx != NULL);
  });
  return running;
}

- (void)setListeningPorts:(NSArray *)listeningPorts {
  NSAssert(listeningPorts.count > 0, @"listeningPorts array cannot be empty!");
  for (id object in listeningPorts) {
    NSAssert([object isKindOfClass:[NSNumber class]], @"listeningPorts must be NSNumbers!");
  }
  dispatch_sync(self.queue, ^{
    if (_ctx == NULL) {
      _listeningPorts = [listeningPorts copy];
    }
  });
}

- (NSArray *)listeningPorts {
  __block NSArray *listeningPorts;
  dispatch_sync(self.queue, ^{
    listeningPorts = [_listeningPorts copy];
  });
  return listeningPorts;
}

- (void)setListeningPort:(NSInteger)port {
  [self setListeningPorts:@[@(port)]];
}

- (NSInteger)listeningPort {
  return [(NSNumber *)self.listeningPorts[0] integerValue];
}

- (void)setDocumentRoot:(NSString *)documentRoot {
  dispatch_sync(self.queue, ^{
    if (_ctx == NULL) {
      _documentRoot = [documentRoot copy];
    }
  });
}

- (NSString *)documentRoot {
  __block NSString *documentRoot;
  dispatch_sync(self.queue, ^{
    documentRoot = [_documentRoot copy];
  });
  return documentRoot;
}


#pragma mark - Mongoose Options

- (NSUInteger)numberOfSupportedOptions {
  return kNumberOfSupportedOptions;
}

- (const char *)nameOfOptionAtIndex:(mongooseOptionIndex)index {
  switch (index) {
    case mongooseOptionIndexDocumentRoot:
      return kMongooseOptionDocumentRoot;
      
    case mongooseOptionIndexListeningPort:
      return kMongooseOptionListeningPorts;
      
    default:
      NSAssert1(false, @"Unexpected option index [%ld]", (long)index);
      return NULL;
  }
}

- (const char *)valueOfOptionAtIndex:(mongooseOptionIndex)index {
  switch (index) {
    case mongooseOptionIndexDocumentRoot:
      return [_documentRoot UTF8String];
      
    case mongooseOptionIndexListeningPort:
      return [[_listeningPorts componentsJoinedByString:@","] UTF8String];
      
    default:
      NSAssert1(false, @"Unexpected option index [%ld]", (long)index);
      return NULL;
  }
}


@end



@implementation MongooseDaemon (MongooseCallbacks)

// Called when mongoose has received new HTTP request.
int begin_request(struct mg_connection *connection)
{
  CIMLog(logMongoose, @"begin_request");
  if (connection == NULL) {
    return 0;
  }
  struct mg_request_info *requestInfo = mg_get_request_info(connection);
  
  MongooseDaemon *daemon = (__bridge MongooseDaemon *)requestInfo->user_data;
  NSHTTPURLResponse *response = nil;
  NSData *responseData = nil;
  if ([daemon.delegate respondsToSelector:@selector(mongooseDaemon:customResponseForRequest:withResponseData:)]) {
    NSURLRequest *request = [MongooseDaemon requestFromMgRequestInfo:requestInfo];
    response = [daemon.delegate mongooseDaemon:daemon customResponseForRequest:request withResponseData:&responseData];
    if (response) {
      NSMutableString *rawHTTPMessage = [[NSMutableString alloc] init];
      
      // STATUS LINE
      // TODO: extract http version string from response
      NSString *status = [NSString stringWithFormat:@"HTTP/1.1 %ld %@\r\n", (long)response.statusCode, [MongooseDaemon responseReasonPhraseForStatusCode:response.statusCode]];
      [rawHTTPMessage appendString:status];
      
      // HEADERS
      NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[response allHeaderFields]];
      // always set content-length
      headers[@"Content-Length"] = @(responseData.length);
      for (NSString *name in headers) {
        NSString *headerString = [NSString stringWithFormat:@"%@: %@\r\n", name, headers[name]];
        [rawHTTPMessage appendString:headerString];
      }
      
      // DATA
      if (responseData.length) {
        // insert blank line before data
        [rawHTTPMessage appendString:@"\r\n"];
        [rawHTTPMessage appendFormat:@"%s", responseData.bytes];
      }
      
      CIMLog(logMongoose, @"rawHTTPMessage:\n%@", rawHTTPMessage);
      mg_printf(connection, "%s", [rawHTTPMessage UTF8String]);
      
      return 1;
      
    } else {
      return 0;
    }
  }
  
  return (response != nil);
}

// Called when mongoose has finished processing request.
void end_request(const struct mg_connection *connection, int reply_status_code)
{
  CIMLog(logMongoose, @"end_request reply_status_code [%d]", reply_status_code);
  if (connection == NULL) {
    return;
  }
  struct mg_request_info *requestInfo = mg_get_request_info(connection);
  MongooseDaemon *daemon = (__bridge MongooseDaemon *)requestInfo->user_data;
  if ([daemon.delegate respondsToSelector:@selector(mongooseDaemon:didCompleteRequest:withStatusCode:)]) {
    NSURLRequest *request = [MongooseDaemon requestFromMgRequestInfo:requestInfo];
    [daemon.delegate mongooseDaemon:daemon didCompleteRequest:request withStatusCode:(NSInteger)reply_status_code];
  }
}

// Called when mongoose is about to log a message.
int log_message(const struct mg_connection *connection, const char *message)
{
  CIMLog(logMongoose, @"log_message message [%s]", message);
  if (connection == NULL) {
    return 0;
  }
  BOOL log = YES;
  struct mg_request_info *requestInfo = mg_get_request_info(connection);
  MongooseDaemon *daemon = (__bridge MongooseDaemon *)requestInfo->user_data;
  if ([daemon.delegate respondsToSelector:@selector(mongooseDaemon:shouldLogMessage:)]) {
    log = [daemon.delegate mongooseDaemon:daemon shouldLogMessage:[NSString stringWithUTF8String:message]];
  }
  return !log;
}

// Called at the beginning of mongoose's thread execution in the context of
// that thread.
void thread_start(void *user_data, void **conn_data)
{
}

// Called when mongoose's thread is about to terminate.
void thread_stop(void *user_data, void **conn_data)
{
}


#pragma mark - Private helper methods

// extract an NSURLRequest from the mg_request_info object
+ (NSURLRequest *)requestFromMgRequestInfo:(const struct mg_request_info *)requestInfo {
  if (requestInfo == NULL) {
    return nil;
  }
  
  NSString *uri = [NSString stringWithUTF8String:requestInfo->uri];
  if (requestInfo->query_string != NULL) {
    uri = [uri stringByAppendingFormat:@"?%s", requestInfo->query_string];
  }
  NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:uri]];
  mutableRequest.HTTPMethod = [NSString stringWithUTF8String:requestInfo->request_method];
  
  for (int i = 0; i < requestInfo->num_headers; i++) {
    struct mg_header header = requestInfo->http_headers[i];
    [mutableRequest setValue:[NSString stringWithUTF8String:header.value] forHTTPHeaderField:[NSString stringWithUTF8String:header.name]];
  }
  
  return [mutableRequest copy];
}

+ (NSString *)responseReasonPhraseForStatusCode:(NSInteger)statusCode {
  NSInteger responseCategory = statusCode / 100;
  
  switch (responseCategory) {
    case 1:
      switch (statusCode) {
        case 100:
          return @"Switching Protocols";
        case 101:
          return @"Continue";
        default:
          return @"Informational";
      }
    case 2:
      switch (statusCode) {
        case 200:
          return @"OK";
        case 201:
          return @"Created";
        case 202:
          return @"Accepted";
        case 203:
          return @"Non-Authoritative Information";
        case 204:
          return @"No Content";
        case 205:
          return @"Reset Content";
        case 206:
          return @"Partial Content";
        default:
          return @"Success";
      }
    case 3:
      switch (statusCode) {
        case 300:
          return @"Multiple Choices";
        case 301:
          return @"Moved Permanently";
        case 302:
          return @"Found";
        case 303:
          return @"See Other";
        case 304:
          return @"Not Modified";
        case 305:
          return @"Use Proxy";
        case 307:
          return @"Temporary Redirect";
        default:
          return @"Redirection";
      }
    case 4:
      switch (statusCode) {
        case 400:
          return @"Bad Request";
        case 401:
          return @"Unauthorized";
        case 402:
          return @"Payment Required";
        case 403:
          return @"Forbidden";
        case 404:
          return @"Not Found";
        case 405:
          return @"Method Not Allowed";
        case 406:
          return @"Not Acceptable";
        case 407:
          return @"Proxy Authentication Required";
        case 408:
          return @"Request Time-out";
        case 409:
          return @"Conflict";
        case 410:
          return @"Gone";
        case 411:
          return @"Length Required";
        case 412:
          return @"Precondition Failed";
        case 413:
          return @"Request Entity Too Large";
        case 414:
          return @"Request-URI Too Large";
        case 415:
          return @"Unsupported Media Type";
        case 416:
          return @"Requested range not satisfiable";
        case 417:
          return @"Expectation Failed";
        default:
          return @"Client Error";
      }
    case 5:
      switch (statusCode) {
        case 500:
          return @"Internal Server Error";
        case 501:
          return @"Not Implemented";
        case 502:
          return @"Bad Gateway";
        case 503:
          return @"Service Unavailable";
        case 504:
          return @"Gateway Time-out";
        case 505:
          return @"HTTP Version not supported";
        default:
          return @"Server Error";
      }
    default:
      return @"Unknown Response";
  }
}


@end
