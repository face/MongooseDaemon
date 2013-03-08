//
//  MongooseDaemon.h
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
//

#import "mongoose.h"

@interface MongooseDaemon : NSObject

/*
 The root directory of the local file system from which Mongoose will serve
 files. Defaults to the documents directory. If the HTTP server is already 
 running, this property will return without changing the value of the property.
 */
@property (nonatomic, strong) NSString *root;

/*
 The port Mongoose will listen for connections on. Defaults to 80. If the HTTP 
 server is already running, this property will return without changing the value
 of the property.
 */
@property (nonatomic, assign) NSInteger port;

/*
 A boolean that indicates if Mongoose is currently running.
 */
@property (nonatomic, readonly, assign, getter = isRunning) BOOL running;


/*
 Blocks until the HTTP server is started. Does nothing if the server is running.
 */
- (void)start;

/*
 Blocks until the HTTP server is stopped. Does nothing if the server is stopped.
 */
- (void)stop;

@end
