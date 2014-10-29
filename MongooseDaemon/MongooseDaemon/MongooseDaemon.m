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
#import "MongooseDaemonVersion.h"
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
const char * kMongooseOptionListeningPort = "listening_port";


@interface MongooseDaemon ()

@property (strong) dispatch_queue_t queue;

@end

@implementation MongooseDaemon {
  struct mg_server *_server;
}

@synthesize documentRoot = _documentRoot;
@synthesize listeningPort = _listeningPort;

- (id)init {
  self = [super init];
  if (self) {
    // create a serial queue
    static int queueCount = 0;
    NSString *queueLabel = [NSString stringWithFormat:@"%@.MongooseQueue.%d", [[NSBundle mainBundle] bundleIdentifier], queueCount++];
    self.queue = dispatch_queue_create([queueLabel UTF8String], NULL);
    dispatch_sync(self.queue, ^{
      CIMLog(logMongoose, @"[%@] created queue [%@]", self, self.queue);
      
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
      _listeningPort = 8080;
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
    if (_server == NULL) {
      
      // start the web server
      _server = mg_create_server((__bridge void *)self);
      
      // set supported options
      NSUInteger i;
      for (i = 0; i < [self numberOfSupportedOptions]; i++) {
        CIMLog(logMongoose, @"%s = %s", [self nameOfOptionAtIndex:i], [self valueOfOptionAtIndex:i]);
        mg_set_option(_server, [self nameOfOptionAtIndex:i], [self valueOfOptionAtIndex:i]);
        CIMLog(logMongoose, @"%s ? %s", [self nameOfOptionAtIndex:i], mg_get_option(_server, [self nameOfOptionAtIndex:i]));
      }
      
      // set callbacks
      mg_set_http_error_handler(_server, &http_error_handler);
      mg_set_request_handler(_server, &request_handler);
      mg_set_auth_handler(_server, &auth_handler);
      
      [self poll];
    }
  });
}

- (void)poll {
  dispatch_async(self.queue, ^{
    if (_server) {
      mg_poll_server(_server, 100);
      [self poll];
    }
  });
}

- (void)stop {
  dispatch_sync(self.queue, ^{
    if (_server != NULL) {
      mg_destroy_server(&_server);
      _server = NULL;
    }
  });
}


#pragma mark - Public Properties

+ (NSString *)versionString {
  NSString *version = [NSString stringWithFormat:@"%.1f", MongooseDaemonVersionNumber];
  return version;
}

+ (NSString *)mongooseVersionString {
  return [NSString stringWithUTF8String:MONGOOSE_VERSION];
}

- (BOOL)isRunning {
  __block BOOL running;
  dispatch_sync(self.queue, ^{
    running = (_server != NULL);
  });
  return running;
}

- (void)setListeningPort:(NSInteger)port {
  dispatch_sync(self.queue, ^{
    _listeningPort = port;
    if (_server != NULL) {
      mg_set_listening_socket(_server, (int)_listeningPort);
    }
  });
}

- (NSInteger)listeningPort {
  __block NSInteger listeningPort;
  dispatch_sync(self.queue, ^{
    listeningPort = _listeningPort;
  });
  return listeningPort;
}

- (void)setDocumentRoot:(NSString *)documentRoot {
  dispatch_sync(self.queue, ^{
    if (_server == NULL) {
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
      return kMongooseOptionListeningPort;
      
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
      return [[NSString stringWithFormat:@"%ld", (long)_listeningPort] UTF8String];
      
    default:
      NSAssert1(false, @"Unexpected option index [%ld]", (long)index);
      return NULL;
  }
}


@end


@implementation MongooseDaemon (MongooseCallbacks)

// called on HTTP errors, should return MG_PROCESSED or MG_NOT_PROCESSED
int http_error_handler(struct mg_connection *connection)
{
  CIMLog(logMongoose, @"http_error_handler status = %d", connection->status_code);
  return MG_ERROR_NOT_PROCESSED;
}

// called on each request, should return MG_REQUEST_PROCESSED, MG_REQUEST_NOT_PROCESSED, or MG_REQUEST_CALL_AGAIN
int request_handler(struct mg_connection *connection)
{
  CIMLog(logMongoose, @"request_handler uri = %s", connection->uri);
  
  MongooseDaemon *daemon = (__bridge MongooseDaemon *)connection->server_param;
  NSHTTPURLResponse *response = nil;
  NSData *responseData = nil;
  if ([daemon.delegate respondsToSelector:@selector(mongooseDaemon:customResponseForRequest:withResponseData:)]) {
    NSURLRequest *request = requestFromMgConnection(connection);
    response = [daemon.delegate mongooseDaemon:daemon customResponseForRequest:request withResponseData:&responseData];
  }
  return sendResponse(connection, response, responseData);
}

// called on each request, should return MG_AUTH_OK or MG_AUTH_FAIL
int auth_handler(struct mg_connection *connection)
{
  CIMLog(logMongoose, @"auth_handler uri = %s", connection->uri);
  return MG_AUTH_OK;
}


#pragma mark - Private Helper Methods

// extract an NSURLRequest from the mg_request_info object
NSURLRequest *requestFromMgConnection(struct mg_connection *connection)
{
  if (connection == NULL) {
    return nil;
  }
  
  NSString *uri = [NSString stringWithUTF8String:connection->uri];
  if (connection->query_string != NULL) {
    uri = [uri stringByAppendingFormat:@"?%s", connection->query_string];
  }
  NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:uri]];
  mutableRequest.HTTPMethod = [NSString stringWithUTF8String:connection->request_method];
  
  for (int i = 0; i < connection->num_headers; i++) {
    struct mg_header header = connection->http_headers[i];
    [mutableRequest setValue:[NSString stringWithUTF8String:header.value] forHTTPHeaderField:[NSString stringWithUTF8String:header.name]];
  }
  
  return [mutableRequest copy];
}

int sendResponse(struct mg_connection *connection, NSHTTPURLResponse *response, NSData *responseData)
{
  if (connection == NULL || !response) return MG_REQUEST_NOT_PROCESSED;
  
  // STATUS
  mg_send_status(connection, response.statusCode);
  
  // HEADERS
  NSMutableDictionary *headers = [[response allHeaderFields] mutableCopy];
  headers[@"Content-Length"] = @(responseData.length);
  for (NSString *name in headers) {
    mg_send_header(connection, [name UTF8String], [[headers[name] stringValue] UTF8String]);
  }
  
  // DATA
  mg_send_data(connection, responseData.bytes, responseData.length);
  
  return MG_REQUEST_PROCESSED;
}


@end
