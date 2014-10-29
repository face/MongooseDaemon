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


@protocol MongooseDaemonDelegate;


/**
 `MongooseDaemon` is an objective C wrapper around the embedable `mongoose` http server for iOS or Mac development. It is ideal for both embedded http services as well as simply debugging your iOS or Mac applications file structure. `MongooseDaemon` is offered under a BSD style license.
 
 `Mongoose` is a lightweight embedable http server written by Sergey Lyubka and offered under a BSD style license. More information on mongoose can be found at the [project's github](https://github.com/valenok/mongoose).
 */
@interface MongooseDaemon : NSObject

/**
 The version of MongooseDaemon
 */
+ (NSString *)versionString;


/**
 The version of the included mongoose library
 */
+ (NSString *)mongooseVersionString;

/**
 Optional delegate to allow for custom responses to be served from memory rather than the file system.
 
 @see MongooseDaemonDelegate
 */
@property (weak) id<MongooseDaemonDelegate> delegate;

/**
 The root directory of the local file system from which Mongoose will serve files. Defaults to the documents directory.
 
 @warning Must be a valid path.
 @warning If the HTTP server is already running, this property will return without changing the value of the property.
 */
@property (nonatomic, strong) NSString *documentRoot;

/**
 An NSInteger defining the port on which Mongoose will listen for connections. Defaults to 8080.
 
 @warning Cannot be empty, can only contain valid port numbers.
 */
@property (nonatomic, assign) NSInteger listeningPort;

/**
 A boolean that indicates if Mongoose is currently running.
 */
@property (nonatomic, readonly, assign, getter = isRunning) BOOL running;


/**
 Starts the Mongoose HTTP server.
 
 Blocks until the HTTP server is started. Does nothing if the server is running.
 */
- (void)start;

/**
 Blocks until the HTTP server is stopped. Does nothing if the server is stopped.
 */
- (void)stop;

@end


/**
 MongooseDaemonDelegate allows Clients to provide custom responses to incoming requests and more visibility into Mongoose as it is running.
 */
@protocol MongooseDaemonDelegate <NSObject>

/**
 Allows the delegate to provide the response to the incoming request instead of allowing Mongoose to serve from the file system.
 
 Returning nil will allow Mongoose to serve the request from the documents folder normally.
 
 @return A valid NSHTTPURLResponse object or nil
 @param daemon A pointer to the MongooseDaemon instance calling the delegate
 @param request The NSURLRequest being handled by MongooseDaemon
 @param responseData OUT A pointer to the response data
 */
- (NSHTTPURLResponse *)mongooseDaemon:(MongooseDaemon *)daemon customResponseForRequest:(NSURLRequest *)request withResponseData:(NSData *__autoreleasing *)responseData;


@end

