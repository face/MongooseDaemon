#MongooseDaemon

`MongooseDaemon` is an objective C wrapper around
the embedable `mongoose` http server for iOS or Mac
development. It is ideal for both embedded http services
as well as simply debugging your iOS or Mac applications
file structure. `MongooseDaemon` is offered under a BSD
style license.

`Mongoose` is a lightweight embedable http server
written by Sergey Lyubka and offered under
a BSD style license. More information on
mongoose can be found at the [project's
github](https://github.com/valenok/mongoose).

##Usage

As of version 1.1, MongooseDaemon is now compiled into a static library for iOS projects and into a framework for Mac OS projects and is meant to be included as a subproject in your workspace.

1. Add MongooseDaemon as a submodule to your project using `git submodule add git@github.com:CIM/MongooseDaemon.git`.
2. Add MongooseDaemon's dependencies using `git submodule update --recursive --init`
3. Add `MongooseDaemon.xcodeproj` to your workspace.
4. Import MongooseDaemon using `#import <MongooseDaemon/MongooseDaemon.h>`

An example iOS app is included with the project that demonstrates how to use MongoseDaemon.

##TODO

- Add support for SSL (!)
- Add support for more of mongoose's options.
- Mac OS example project.
- Make a CocoaPod because everything uses CocoaPods now.
- Add some tests or else no one will take this serioiusly.

---

Copyright (c) 2008 Rama McIntosh, 2013 CIM
Released under the BSD license found in the file LICENSE
