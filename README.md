#MongooseDaemon

`MongooseDaemon` is an objective C wrapper around
the embedable mongoose http server for iPhone
development.  It is offered under a BSD
style license.

`MongooseDaemon` is ideal for both embedded http services
as well as simply debugging your iPhone applications
file structure.

`Mongoose` is a lightweight embedable http server
written by Sergey Lyubka and offered under
a BSD style license.  More information on
mongoose can be found at the [project's
site](http://code.google.com/p/mongoose/).

**NOTE:** `mongoose.h` and `mongoose.c` are taken
directly from mongoose-2.6 and are unmodified.
They are simply forked in this package for
convenience and stability.

##Usage

Clone the mongoose directory and add it to your X-Code project.

Then you can start it within one of your classes to
provide http access to your iPhone application.

For example, to start MongooseDaemon when your application
starts on port 8080:

Add the following to MyAppDelegate.m:
  ...
  #import "MongooseDaemon.h"
  ....
  @interface MyAppDelegate () {
    ...
    MongooseDaemon    *mongooseDaemon;
    ...
  }
  ...
  @implementation MyAppDelegate
  ...
  - (void)applicationDidFinishLaunching:(UIApplication *)application {
  mongooseDaemon = [[MongooseDaemon alloc] init];
  mongooseDaemon.port = 8080;
  [mongooseDaemon start];
  ...
  - (void)dealloc {
  ...
    [mongooseDaemon stop];
    [mongooseDaemon release];
  ...
  }

And that's it!

TODO
=======
1) Add a helper method to return the server's URL for
convience

2) Add support for some of mongoose's rich feature set.

3) Investigate if there is anyway to serve files over endge/3g instead of just WiFi.

==============

Copyright (c) 2008 Rama McIntosh
Released under the BSD license found in the file LICENSE
