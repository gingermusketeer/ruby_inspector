# RubyInspector

Allows for ruby apps to be debugged using the standard chrome developer tools

# Demo

![RubyInspector demo gif](https://raw.githubusercontent.com/gingermusketeer/ruby_inspector/master/readme/demo.gif)

See [RubyInspector demos](https://github.com/gingermusketeer/ruby_inspector_demos) for more examples

# Getting started

1. Get a copy of [chrome devtools app](https://github.com/auchenberg/chrome-devtools-app)
2. Setup and start [ruby_inspector_server](https://github.com/gingermusketeer/ruby_inspector_server)
3. Run `ruby demo.rb`
4. Connect the devtools app to your app. apps -> Go
5. Unleash the app from the breakpoint
6. Monitor http traffic


# Todo
- Start the server automatically in the background unless it is started (server.pid?)
- Pull the tcp socket port from the node app (socket.port?)
- Add ruby script debugging via byebug
