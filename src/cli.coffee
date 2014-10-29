Pkr = require '..'
fs = require 'fs'
pa = require 'path'

# remove fist two items
process.argv.shift()
process.argv.shift()

if process.argv.length
	file = pa.resolve process.argv.shift()
	schema = process.argv.shift()
	
	if schema
		JSON.loadRemoteSchema schema, (err) ->
			if err then return console.error "Failed to load schema.", err.stack
			
			JSON.validate fs.readFileSync(file, 'utf8'), JSON.SCHEMAS[schema]
			
			console.log "JSON is valid."
			
	else
		console.error "No schema specified."

else
	console.error "No JSON specified."