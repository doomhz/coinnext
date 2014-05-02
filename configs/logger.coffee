consoleLog = console.log
consoleError = console.error

console.log = ()->
  args = arguments
  args[0] = "#{new Date().toGMTString()} - log: #{args[0]}"  if args[0]
  consoleLog.apply undefined, args

console.error = ()->
  args = arguments
  args[0] = "#{new Date().toGMTString()} - error: #{args[0]}"  if args[0]
  consoleError.apply undefined, args

process.on "uncaughtException", (err)->
  console.error "Uncaught exception, exiting...", err.stack
  process.exit()