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


#define DOCUMENTS_FOLDER NSHomeDirectory()


#define MONGOOSE_OPTION_DOCUMENT_ROOT "document_root"
#define MONGOOSE_OPTION_LISTENING_PORTS "listening_ports"


@interface MongooseDaemon ()

@property (strong) dispatch_queue_t queue;

@end

@implementation MongooseDaemon {
  struct mg_context *_ctx;
  struct mg_callbacks callbacks;
}

@synthesize documentRoot = _documentRoot;
@synthesize listeningPorts = _listeningPorts;

- (id)init {
  self = [super init];
  if (self) {
    // create a serial queue
    static int queueCount = 0;
    NSString *queueLabel = [NSString stringWithFormat:@"%@.MongoseQueue.%d", [[NSBundle mainBundle] bundleIdentifier], queueCount++];
    self.queue = dispatch_queue_create([queueLabel UTF8String], NULL);
    dispatch_sync(self.queue, ^{
      NSLog(@"[%@] created queue [%@]", self, self.queue);
      
      // Prepare callbacks structure.
      memset(&callbacks, 0, sizeof(callbacks));
      callbacks.begin_request = &begin_request;
      callbacks.end_request = &end_request;
      callbacks.log_message = &log_message;
//      callbacks.init_ssl = &init_ssl; // SSL requires libssl.dylib
      callbacks.websocket_connect = &websocket_connect;
      callbacks.websocket_ready = &websocket_ready;
      callbacks.websocket_data = &websocket_data;
      callbacks.open_file = &open_file;
      callbacks.init_lua = &init_lua;
      callbacks.upload = &upload;
      callbacks.thread_start = &thread_start;
      callbacks.thread_stop = &thread_stop;
      
      // list available options and their defaults
      const char **options = mg_get_valid_option_names();
      NSMutableDictionary *validOptions = [NSMutableDictionary dictionary];
      int i;
      for (i = 0; options[i * 2] != NULL; i++) {
        NSString *option = [NSString stringWithUTF8String:options[i * 2]];
        if (options[i * 2 + 1] == NULL) {
          validOptions[option] = [NSNull null];
        } else {
          validOptions[option] = [NSString stringWithUTF8String:options[i * 2 + 1]];
        }
      }
      NSLog(@"Available Mongoose Options = %@", validOptions);
      
      // set port and root defaults
      _listeningPorts = @[@8080];
      _documentRoot = DOCUMENTS_FOLDER;
      
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
      const char *options[] = {
        MONGOOSE_OPTION_DOCUMENT_ROOT, [_documentRoot UTF8String],
        MONGOOSE_OPTION_LISTENING_PORTS, [[_listeningPorts componentsJoinedByString:@","] UTF8String],
        NULL
      };
      
      // start the web server
      _ctx = mg_start(&callbacks, NULL, options);     // Start Mongoose serving thread
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


@end



@implementation MongooseDaemon (MongooseCallbacks)
// TODO: fire delegate methods

// Called when mongoose has received new HTTP request.
int begin_request(struct mg_connection *connection)
{
  NSLog(@"begin_request");
  return 0;
}

// Called when mongoose has finished processing request.
void end_request(const struct mg_connection *connection, int reply_status_code)
{
  NSLog(@"end_request: reply_status_code[%d]", reply_status_code);
}

// Called when mongoose is about to log a message.
int log_message(const struct mg_connection *connection, const char *message)
{
  NSLog(@"log_message: message[%s]", message);
  return 0;
}

// Called when mongoose initializes SSL library.
int init_ssl(void *ssl_context, void *user_data)
{
  NSLog(@"init_ssl");
  return 0;
}

// Called when websocket request is received, before websocket handshake.
int websocket_connect(const struct mg_connection *connection)
{
  NSLog(@"websocket_connect");
  return 0;
}

// Called when websocket handshake is successfully completed, and
// connection is ready for data exchange.
void websocket_ready(struct mg_connection *connection)
{
  NSLog(@"websocket_ready");
}

// Called when data frame has been received from the client.
int websocket_data(struct mg_connection *connection, int bits, char *data, size_t data_len)
{
  NSLog(@"websocket_data: data[%s] data_len[%ld]", data, data_len);
  return 0;
}

// Called when mongoose tries to open a file.
const char *open_file(const struct mg_connection *connection, const char *path, size_t *data_len)
{
  NSLog(@"open_file: path[%s] data_len[%ld]", path, *data_len);
  // NULL means serve from file
  return NULL;
}

// Called when mongoose is about to serve Lua server page
void init_lua(struct mg_connection *connection, void *lua_context)
{
  NSLog(@"init_lua");
}

// Called when mongoose has uploaded a file to a temporary directory
void upload(struct mg_connection *connection, const char *file_name)
{
  NSLog(@"upload: file_name[%s]", file_name);
}

// Called at the beginning of mongoose's thread execution in the context of
// that thread.
void thread_start(void *user_data, void **conn_data)
{
  NSLog(@"thread_start");
}

// Called when mongoose's thread is about to terminate.
void thread_stop(void *user_data, void **conn_data)
{
  NSLog(@"thread_stop");
}


@end
