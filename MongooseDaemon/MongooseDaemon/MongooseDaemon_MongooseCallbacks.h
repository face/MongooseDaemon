//
//  MongooseDaemon_MongooseCallbacks.h
//  MongooseDaemon
//
//  Created by Ibanez, Jose on 11/25/13.
//  Copyright (c) 2013 CIM. All rights reserved.
//

#import "MongooseDaemon.h"
#import "mongoose.h"

@interface MongooseDaemon (MongooseCallbacks)

// Called when mongoose has received new HTTP request.
int begin_request(struct mg_connection *);

// Called when mongoose has finished processing request.
void end_request(const struct mg_connection *, int reply_status_code);

// Called when mongoose is about to log a message.
int log_message(const struct mg_connection *, const char *message);

// Called when mongoose initializes SSL library.
int init_ssl(void *ssl_context, void *user_data);

// Called when websocket request is received, before websocket handshake.
int websocket_connect(const struct mg_connection *);

// Called when websocket handshake is successfully completed, and
// connection is ready for data exchange.
void websocket_ready(struct mg_connection *);

// Called when data frame has been received from the client.
int websocket_data(struct mg_connection *, int bits, char *data, size_t data_len);

// Called when mongoose tries to open a file.
const char *open_file(const struct mg_connection *, const char *path, size_t *data_len);

// Called when mongoose is about to serve Lua server page
void init_lua(struct mg_connection *, void *lua_context);

// Called when mongoose has uploaded a file to a temporary directory
void upload(struct mg_connection *, const char *file_name);

// Called at the beginning of mongoose's thread execution in the context of
// that thread.
void thread_start(void *user_data, void **conn_data);

// Called when mongoose's thread is about to terminate.
void thread_stop(void *user_data, void **conn_data);


@end
