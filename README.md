# RubyInspector

Allows for ruby apps to be debugged using the standard chrome developer tools

# Demo

![RubyInspector demo gif](https://raw.githubusercontent.com/gingermusketeer/ruby_inspector/master/readme/demo.gif)

See [RubyInspector demos](https://github.com/gingermusketeer/ruby_inspector_demos) for more examples

# Getting started

1. Get a copy of [chrome devtools app](https://github.com/auchenberg/chrome-devtools-app)
2. Setup and start [ruby_inspector_server](https://github.com/gingermusketeer/ruby_inspector_server)
3. Add `gem 'ruby_inspector'` to your gem file
4. Add `RubyInspector.enable("MyAppName", "Optional description")` to enable monitoring
5. Add a breakpoint before the network requests are made
6. Connect the devtools app to your app. apps -> Go
7. Unleash the app from the breakpoint
8. Monitor http traffic


# Todo
- Start the server automatically in the background unless it is started (server.pid?)
- Pull the tcp socket port from the node app (socket.port?)
- Add ruby script debugging via byebug
