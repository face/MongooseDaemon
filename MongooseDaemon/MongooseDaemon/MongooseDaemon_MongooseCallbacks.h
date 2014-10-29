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

// called on HTTP errors, should return MG_PROCESSED or MG_NOT_PROCESSED
int http_error_handler(struct mg_connection *connection);

// called on each request, should return MG_REQUEST_PROCESSED, MG_REQUEST_NOT_PROCESSED, or MG_REQUEST_CALL_AGAIN
int request_handler(struct mg_connection *connection);

// called on each request, should return MG_AUTH_OK or MG_AUTH_FAIL
int auth_handler(struct mg_connection *connection);

@end
