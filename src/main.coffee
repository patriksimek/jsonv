DEBUG = false

RESOLVE_TYPE = (json) ->
	unless json? then return 'null'
	
	switch typeof json
		when 'object'
			if Array.isArray json
				return 'array'
			if json instanceof Date
				return 'date'
			else
				return 'object'
		else
			return typeof json

JSON.FORMAT_VALIDATOR =
	'date-time': (json, schema, path) ->
		if not (/^(\d{4}\-\d\d\-\d\d(T[\d:\.]*)?)(Z|([+\-])(\d\d):?(\d\d))?$/i).test json
			return new Error "String is not valid date-time at path '#{path}'."
		
		null
		
	'email': (json, schema, path) ->
		if not (/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$/i).test json
			return new Error "String is not valid email at path '#{path}'."
		
		null
	
	'uri': (json, schema, path) ->
		if not (/(http|ftp|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:\/~+#-]*[\w@?^=%&amp;\/~+#-])?/i).test json
			return new Error "String is not valid email at path '#{path}'."
		
		null
	
	'ipv4': (json, schema, path) ->
		if not (/^(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))$/).test json
			return new Error "String is not valid IPv4 at path '#{path}'."
		
		null
	
	'ipv6': (json, schema, path) ->
		if not (/^((?=.*::)(?!.*::.+::)(::)?([\dA-F]{1,4}:(:|\b)|){5}|([\dA-F]{1,4}:){6})((([\dA-F]{1,4}((?!\3)::|:\b|$))|(?!\2\3)){2}|(((2[0-4]|1\d|[1-9])?\d|25[0-5])\.?\b){4})$/i).test json
			return new Error "String is not valid IPv6 at path '#{path}'."
		
		null
	
	'hostname': (json, schema, path) ->
		if not (/^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$/i).test json
			return new Error "String is not valid hostname at path '#{path}'."
		
		null

JSON.TYPE_VALIDATOR =
	object: (json, schema, path) ->
		if DEBUG then console.log 'OBJ', path
		#console.log 'OBJ', json, schema
			
		if not json? or typeof json isnt 'object' or Array.isArray(json) or json instanceof Date
			@error = new Error "Expected object at path '#{path}'."
			return json
		
		properties = Object.keys(json)
		len = properties.length
		
		if schema.minProperties > 0 and len < schema.minProperties
			@error = new Error "Object has less properties than expected at path '#{path}'."
			return json
		
		if schema.maxProperties > 0 and len > schema.maxProperties
			@error = new Error "Object has more properties than expected at path '#{path}'."
			return json

		if schema.required
			for prop in schema.required
				unless Object::hasOwnProperty.call json, prop
					if schema.properties?[prop]?.default?
						unless Object::hasOwnProperty.call json, prop
							properties.push prop
						
						json[prop] = schema.properties[prop].default
					
					else
						@error = new Error "Required property '#{prop}' is missing at path '#{path}'."
						return json
		
		if schema.dependencies?
			for name, dep of schema.dependencies
				if Object::hasOwnProperty.call json, name
					if Array.isArray dep
						for d in dep
							unless Object::hasOwnProperty.call json, d
								@error = new Error "Dependency '#{d}' required at path '#{path}'."
								return json
					
					else if typeof dep is 'object'
						@validate name, json, dep
		
		while len--
			name = properties.shift()
			found = false
			
			if schema.properties?[name]?
				@validate name, json[name], schema.properties[name]
				found = true

			if schema.patternProperties?
				for regexp of schema.patternProperties
					if new RegExp(regexp).test name
						@validate name, json[name], schema.patternProperties[regexp]
						found = true
			
			if not found and typeof schema.additionalProperties is 'object'
				@validate name, json[name], schema.additionalProperties
				found = true
			
			if not found and schema.additionalProperties is false
				@error = new Error "Additional property '#{name}' found, but additional properties are now allowed at path '#{path}'."
				return json

		json
	
	array: (json, schema, path) ->
		if DEBUG then console.log 'ARR', path
		#console.log 'ARR', json, schema
			
		unless Array.isArray json
			@error = new Error "Expected array at path '#{path}'."
			return json
		
		if schema.minItems > 0 and json.length < schema.minItems
			@error = new Error "Array has less items than expected at path '#{path}'."
			return json
		
		if schema.maxItems > 0 and json.length > schema.maxItems
			@error = new Error "Array has more items than expected at path '#{path}'."
			return json
		
		if schema.uniqueItems is true
			array = json.map (item) ->
				if typeof item is 'object'
					JSON.stringify item
				else
					item
				
			unique = array.filter (value, index) ->
				array.indexOf(value) is index
				
			if unique.length isnt json.length
				@error = new Error "Items of array are not unique at path '#{path}'."
				return json
		
		if Array.isArray schema.items
			for i, index in json
				if schema.items[index]?
					@validate index, i, schema.items[index]
				
				else if typeof schema.additionalItems is 'object'
					@validate index, i, schema.additionalItems
				
				else if schema.additionalItems is false
					@error = new Error "Additional item '#{index}' found, but additional items are now allowed at path '#{path}'."
					return json
		
		else if typeof schema.items is 'object'
			for i, index in json
				@validate index, i, schema.items
		
		json
	
	number: (json, schema, path) ->
		if DEBUG then console.log 'NUM', path
		#console.log 'NUM', json, schema
		
		if not json? and schema.default?
			return schema.default
			
		unless typeof json is 'number'
			@error = new Error "Expected number at path '#{path}'."
			return json
		
		if schema.minimum > 0 and ((schema.exclusiveMinimum is true and json <= schema.minimum) or json < schema.minimum)
			@error = new Error "Number is lower than '#{schema.minimum}' at path '#{path}'."
			return json
		
		if schema.maximum > 0 and ((schema.exclusiveMaximum is true and json >= schema.maximum) or json > schema.maximum)
			@error = new Error "Number is greater than '#{schema.maximum}' at path '#{path}'."
			return json
		
		if schema.divisibleBy > 0 and (json % schema.divisibleBy) isnt 0
			@error = new Error "Number is is not divisible by '#{schema.divisibleBy}' at path '#{path}'."
			return json
		
		if schema.multipleOf > 0 and (json / schema.multipleOf % 1) isnt 0
			@error = new Error "Number is is not multiple of '#{schema.multipleOf}' at path '#{path}'."
			return json
		
		json
	
	integer: (json, schema, path) ->
		if DEBUG then console.log 'INT', path
		#console.log 'INT', json, schema
		
		if not json? and schema.default?
			return schema.default
		
		unless typeof json is 'number'
			@error = new Error "Expected integer at path '#{path}'."
			return json
		
		if schema.minimum? and ((schema.exclusiveMinimum is true and json <= schema.minimum) or json < schema.minimum)
			@error = new Error "Integer is lower than '#{schema.minimum}' at path '#{path}'."
			return json
		
		if schema.maximum? and ((schema.exclusiveMaximum is true and json >= schema.maximum) or json > schema.maximum)
			@error = new Error "Integer is greater than '#{schema.maximum}' at path '#{path}'."
			return json
		
		if schema.divisibleBy? and (json % schema.divisibleBy) isnt 0
			@error = new Error "Integer is is not divisible by '#{schema.divisibleBy}' at path '#{path}'."
			return json
		
		if schema.multipleOf? and (json / schema.multipleOf % 1) isnt 0
			@error = new Error "Integer is is not multiple of '#{schema.multipleOf}' at path '#{path}'."
			return json
		
		if json % 1 isnt 0
			@error = new Error "Expected integer at path '#{path}'."
			return json
		
		json
	
	string: (json, schema, path) ->
		if DEBUG then console.log 'STR', path
		#console.log 'STR', json, schema
		
		if not json? and schema.default?
			return schema.default
		
		unless typeof json is 'string'
			@error = new Error "Expected string at path '#{path}'."
			return json
		
		if schema.minLength > 0 and json.length < schema.minLength
			@error = new Error "String is smaller than '#{schema.minLength}' chars at path '#{path}'."
			return json
		
		if schema.maxLength > 0 and json.length > schema.maxLength
			@error = new Error "String is larger than '#{schema.maxLength}' chars at path '#{path}'."
			return json
		
		if schema.pattern?
			unless new RegExp(schema.pattern).test json
				@error = new Error "String doesn't match pattern at path '#{path}'."
				return json
		
		if schema.format
			if not JSON.FORMAT_VALIDATOR[schema.format]?
				@error = new Error "Unknown format '#{schema.format}' at path '#{path}'."
				return json
			
			@error = JSON.FORMAT_VALIDATOR[schema.format] json, schema, path
			if @error then return json
		
		json
	
	boolean: (json, schema, path) ->
		if DEBUG then console.log 'BOO', path
		#console.log 'BOO', json, schema
		
		if not json? and schema.default?
			return schema.default
		
		unless typeof json is 'boolean'
			@error = new Error "Expected boolean at path '#{path}'."
			return json
		
		json
	
	date: (json, schema, path) ->
		if DEBUG then console.log 'DAT', path
		#console.log 'BOO', json, schema
		
		if not json? and schema.default?
			return schema.default
		
		if json not instanceof Date
			@error = new Error "Expected date at path '#{path}'."
			return json
		
		json
	
	'null': (json, schema, path) ->
		if DEBUG then console.log 'NUL', path
		##console.log 'NUL', json, schema
		
		if json isnt null
			@error = new Error "Expected null at path '#{path}'."
			return json
		
		json
	
	any: (json, schema, path) ->
		if DEBUG then console.log 'ANY', path
		
		json

REF = (path, mode = 'schema') ->
	path = path.split '#'
	uri = path.shift()

	if uri
		if JSON.SCHEMAS[uri]
			@[mode] = JSON.SCHEMAS[uri]
		
		else
			if @options.async
				console.warn '[jsonv] Remote schemas are not supported yet.'
				return {}
			
			else
				console.warn '[jsonv] Remote schemas are not available in synchronous mode.'
				return {}
	
	path = path.pop()
	if path?.substr(0, 1) is '/'
		path = path.split('/') ? []
		path.shift() # remove first empty item
	
		cur = @[mode].root
		while cur and path.length
			cur = cur[path.shift()]
		
		if cur?.$ref
			return REF.call @, cur.$ref, mode
		
		else
			return cur
	
	else if path
		return @[mode].ref?["##{path}"]
	
	else
		@[mode].root

VALIDATE_SUBSCHEMA = (document, schema, path, depth) ->
	errors = []
	context =
		document: @document
		schema: @schema
		options: @options
	
	if schema.$ref?
		schema = REF.call context, schema.$ref
		unless schema
			return document: document, suberrors: [new Error "Schema reference not found at path '#{path}'"]

	# --- Prepare context ---
	
	queue = null
	ctx =
		error: null
		options: @options
		validate: (name, document, schema) ->
			queue ?= []
			queue.push
				name: name
				document: document
				schema: schema

	# --- Enumerable values ---
	
	if Array.isArray schema.enum
		found = false
		
		for item in schema.enum
			if typeof item is 'object'
				# deep equal of objects
				if JSON.stringify(item) is JSON.stringify(document)
					found = true
					break
			
			else
				if item is document
					found = true
					break
			
		unless found
			errors.push new Error "Not found in enumerated values at path '#{path}'."
	
	type = schema.type ? RESOLVE_TYPE document
	
	if Array.isArray type
		found = false
		
		for t in type
			unless JSON.TYPE_VALIDATOR[t]
				errors.push new Error "Unknown type '#{t}' at path '#{path}'."
			
			else
				ctx.error = null
				document = JSON.TYPE_VALIDATOR[t].call ctx, document, schema, path
				unless ctx.error
					found = true
					break
				
		if not found
			errors.push new Error "Validation failed for all types at path '#{path}'."
	
	else
		if not JSON.TYPE_VALIDATOR[type]
			errors.push new Error "Unknown type '#{schema.type}' at path '#{path}'."
		
		else
			document = JSON.TYPE_VALIDATOR[type].call ctx, document, schema, path
			if ctx.error
				errors.push ctx.error
	
	# --- Process queued nodes ---

	if queue?.length
		for item in queue
			res = VALIDATE.call context, item.document, item.schema, "#{if path is '/' then '' else path}/#{item.name}", depth + 1
			document[item.name] = res.document
			
			errors.push err for err in res.errors
	
	document: document
	suberrors: errors

###
@param {*} document
@param {*} schema
@param {String} path
@param {Number} depth
###

VALIDATE = (document, schema, path = '/', depth = 1) ->
	#console.log 'DOC', document
	#console.log 'SCH', schema
	#console.log 'PAT', path
	#console.log 'DEP', depth
	
	context =
		document: @document
		schema: @schema
		options: @options
	
	if @options.followRefs and document?.$ref?
		document = REF.call context, document.$ref, 'document'
		unless document
			return document: document, errors: [new Error "Reference not found at path '#{path}'"]
	
	if schema.$ref?
		schema = REF.call context, schema.$ref
		unless schema
			return document: document, errors: [new Error "Schema reference not found at path '#{path}'"]
	
	if Array.isArray schema.allOf
		schemas = schema.allOf
		mode = 'all'
	
	else if Array.isArray schema.anyOf
		schemas = schema.anyOf
		mode = 'any'
	
	else if Array.isArray schema.oneOf
		schemas = schema.oneOf
		mode = 'one'
	
	else
		schemas = []
		mode = ''
	
	errors = []
	valids = 0
	
	# Validate base schema
	{suberrors, document} = VALIDATE_SUBSCHEMA.call context, document, schema, path, depth
	
	if suberrors.length
		errors.push err for err in suberrors
		return document: document, errors: errors
	
	# Validate not schema
	
	if schema['not']?
		{suberrors} = VALIDATE_SUBSCHEMA.call context, document, schema['not'], path, depth
		
		if not suberrors.length
			errors.push new Error "Data matches schema but it should not at path '#{path}'."
			return document: document, errors: errors
	
	# Validate sub schemas
	for schema in schemas
		{suberrors} = VALIDATE_SUBSCHEMA.call context, document, schema, path, depth

		if suberrors.length
			# schema is not valid
			
			if mode is 'all'
				errors.push err for err in suberrors
				return document: document, errors: errors
		
		else
			# schema is valid
			valids++
			
			if mode is 'any'
				return document: document, errors: errors

	if (mode is 'any' or mode is 'one') and valids is 0
		errors.push new Error "None of subschemas is valid at path '#{path}'."

	if mode is 'one' and valids > 1
		errors.push new Error "More than one subschema is valid at path '#{path}'."

	document: document
	errors: errors

###
@param {Document} document
@param {Schema} schema
@param {Object} options
###

SYNC = (document, schema, options) ->
	# --- Pre-validations ---
	
	if options.maxLength and typeof document is 'string'
		if document.length > options.maxLength
			throw new Error "Maximum JSON size exceeded."
	
	# --- Validations ---

	context =
		document: document
		schema: schema
		options: options

	{errors, document} = VALIDATE.call context, document.root, schema.root
	
	if errors.length
		ex = new JSONValidationError "Validation failed with #{errors.length} error(s)."
		ex.suberrors = errors ? []
		throw ex
	
	document

JSON.SCHEMAS = {}
JSON.validate = (document, schema, options, callback) ->
	if options instanceof Function
		callback = options
		options = null
	
	options ?= {}
	options.async = callback?

	if options.async
		try
			document = new Document document
			schema = JSON.addSchema schema
			document = SYNC document, schema, options
			
			return process.nextTick ->
				callback null, document
			
		catch ex
			process.nextTick ->
				callback ex
	
	else
		document = new Document document
		schema = JSON.addSchema schema
		return SYNC document, schema, options

JSON.addSchema = (schema) ->
	if typeof schema is 'string'
		try
			schema = JSON.parse schema
		catch ex
			throw new Error "Failed to parse schema. #{ex.message}."
	
	if typeof schema is 'object'
		if schema instanceof Schema
			return schema
	
		schema = new Schema schema
		if schema.uri then JSON.SCHEMAS[schema.uri] = schema
	
	else
		throw new Error "Invalid schema."
	
	schema

JSON.loadRemoteSchema = (url, callback) ->
	options = require('url').parse url
	options.method = 'GET'
	
	req = require(if options.protocol is 'https:' then 'https' else 'http').request options, (res) ->
		data = ''
		
		if res.statusCode isnt 200
			return callback new Error "Server respond with #{res.statusCode}."
		
		res.setEncoding 'utf8'
		res.on 'data', (chunk) ->
			data += chunk
		
		res.on 'end', ->
			try
				JSON.addSchema data
			catch ex
				return callback ex
				
			callback null

	req.on 'error', callback
	req.end()

class Document
	root: null
	
	constructor: (root) ->
		try
			@root = JSON.parse root
			
		catch ex
			throw new Error "Failed to parse JSON."

class Schema
	uri: ''
	root: null
	ref: null
	
	constructor: (@root) ->
		@ref = {}
		@uri = @root.$schema?.split('#')[0]

		@analyze()
	
	analyze: (node = @root) ->
		if Array.isArray node
			@analyze item for item in node
		
		else
			if node.id
				@ref[node.id] = node
				
			@analyze value for key, value of node when typeof value is 'object'
		
		null
	
class global.JSONValidationError extends Error
	constructor: (message, suberrors) ->
		unless @ instanceof JSONValidationError
			err = new JSONValidationError message, suberrors
			Error.captureStackTrace err, arguments.callee
			return err
		
		@name = @constructor.name
		@message = message
		@suberrors = suberrors ? []
		
		super()
		Error.captureStackTrace @, @constructor
	
	toString: ->
		"[JSONValidationError: #{@message}]\n - #{@suberrors.map((err) -> err.message).join('\n - ')}"
	
	inspect: ->
		@toString()