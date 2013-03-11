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

// MongooseDaemon is a small wrapper to make ingetrating mongoose
// with iPhone apps super easy

#import "MongooseDaemon.h"
#import "mongoose.h"
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

//#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define DOCUMENTS_FOLDER NSHomeDirectory()


#define MONGOOSE_OPTION_DOCUMENT_ROOT "document_root"
#define MONGOOSE_OPTION_LISTENING_PORTS "listening_ports"


@interface MongooseDaemon ()

@end

@implementation MongooseDaemon {
  dispatch_queue_t _queue;
  struct mg_context *_ctx;
  NSString *_documentRoot;
  NSArray *_listeningPorts;
}

- (id)init {
  self = [super init];
  if (self) {
    // create a serial queue
    static NSInteger queueCount = 0;
    NSString *queueLabel = [NSString stringWithFormat:@"%@.Mongoose.%d", [[NSBundle mainBundle] bundleIdentifier], queueCount];
    _queue = dispatch_queue_create([queueLabel UTF8String], NULL);
    queueCount++;
    
    // set port and root defaults
    _listeningPorts = @[@8080];
    _documentRoot = DOCUMENTS_FOLDER;
    
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
  }
  return self;
}

- (void)dealloc {
  [self stop];
  self.documentRoot = nil;
}


#pragma mark - start/stop

- (void)start {
  dispatch_sync(_queue, ^{
    if (_ctx == NULL) {
      
      // Prepare callbacks structure. We have no callbacks, all are NULL.
      // TODO: add callbacks, fire delegate methods
      struct mg_callbacks callbacks;
      memset(&callbacks, 0, sizeof(callbacks));
      
      // List of options. Last element must be NULL.
      // TODO: 
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
  dispatch_sync(_queue, ^{
    if (_ctx != NULL) {
      mg_stop(_ctx);
      _ctx = NULL;
    }
  });
}


#pragma mark - Public Properties

- (BOOL)isRunning {
  __block BOOL running;
  dispatch_sync(_queue, ^{
    running = (_ctx != NULL);
  });
  return running;
}

- (void)setListeningPorts:(NSArray *)listeningPorts {
  dispatch_sync(_queue, ^{
    if (_ctx == NULL) {
      _listeningPorts = [listeningPorts copy];
    }
  });
}

- (NSArray *)listeningPorts {
  __block NSArray *listeningPorts;
  dispatch_sync(_queue, ^{
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
  dispatch_sync(_queue, ^{
    if (_ctx == NULL) {
      _documentRoot = [documentRoot copy];
    }
  });
}

- (NSString *)documentRoot {
  __block NSString *documentRoot;
  dispatch_sync(_queue, ^{
    documentRoot = [_documentRoot copy];
  });
  return documentRoot;
}


@end
