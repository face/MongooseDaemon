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

//#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define DOCUMENTS_FOLDER NSHomeDirectory()

@implementation MongooseDaemon

@synthesize ctx;


- (void)threadMain
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];

  [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
   while(true) {
     [runLoop run]; 
   }
   [pool release];
}

- (void)startHTTP:(NSString *)ports
{
  ctx = mg_start();     // Start Mongoose serving thread
  mg_set_option(ctx, "root", [DOCUMENTS_FOLDER UTF8String]);  // Set document root
  mg_set_option(ctx, "ports", [ports UTF8String]);    // Listen on port XXXX
  //mg_bind_to_uri(ctx, "/foo", &bar, NULL); // Setup URI handler

  // Now Mongoose is up, running and configured.
  // Serve until somebody terminates us
  NSLog(@"Server should be running");
  for (;;)
    getchar();
}

- (void)startMongooseDaemon:(NSString *)ports;
{
  httpThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain) object:nil];
  [httpThread start];
  [self performSelector:@selector(startHTTP:) onThread:httpThread withObject:ports waitUntilDone:NO];
}

- (void)stopMongooseDaemon
{
  mg_stop(ctx);
  [httpThread cancel];
  [httpThread release];
}

@end
