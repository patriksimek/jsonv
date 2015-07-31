assert = require "assert"
fs = require "fs"

describe 'JSON Validator', ->
	it 'should validate simple JSON #1', (done) ->
		json = "11"
		schema =
			type: "number"
		
		result = JSON.validate json, schema
		
		assert.strictEqual result, 11
		
		done()
		
	it 'should validate simple JSON #2', (done) ->
		json = '{"mynum": 11, "mynums": [12, 13, 14], "notmynums": null}'
		schema = 
			type: "object"
			properties:
				"mynum":
					type: "number"
				
				"mynums": 
					type: "array"
					items:
						type: "number"
				
				"notmynums":
					type: "number"
					default: 11
			
			additionalProperties: false
		
		result = JSON.validate json, schema
		
		assert.strictEqual result.mynum, 11
		assert.strictEqual result.mynums.length, 3
		assert.strictEqual result.mynums[0], 12
		assert.strictEqual result.mynums[1], 13
		assert.strictEqual result.mynums[2], 14
		
		done()
		
	it 'should validate complex JSON #1', (done) ->
		JSON.addSchema
			$schema: 'test#'
			type: "object"
			properties:
				"mynum":
					type: "number"
				
				"mynums": 
					$ref: "#myid"
					
			additionalProperties: false
			
			definitions:
				"mynums":
					id: "#myid"
					type: "array"
					items:
						type: "number"
		
		json = '{"mynum": 11, "mynums": [{"$ref": "#/mynum"}, {"$ref": "#/mynum"}, 14]}'
		schema = 
			$ref: 'test#'

		JSON.validate json, schema, {followRefs: true}, (err, result) ->
			if err then return done err
			
			assert.strictEqual result.mynum, 11
			assert.strictEqual result.mynums.length, 3
			assert.strictEqual result.mynums[0], 11
			assert.strictEqual result.mynums[1], 11
			assert.strictEqual result.mynums[2], 14
	
			done()
	
	it 'should validate document size', (done) ->
		json = '{"mynum": 11, "mynums": [{"$ref": "#/mynum"}, {"$ref": "#/mynum"}, 14]}'
		schema = 
			type: "object"
			
		JSON.validate json, schema, {maxLength: 10}, (err, result) ->
			assert.ok err
			
			JSON.validate json, schema, {maxLength: 100}, done

readDir = (dirname) ->
	for dir in (dir for dir in fs.readdirSync(dirname) when not fs.lstatSync("#{dirname}/#{dir}").isDirectory())
		do (dir) ->
			suites = require "#{dirname}/#{dir}"
			
			describe dir, ->
				for suite in suites
					do (suite) ->
						describe suite.description, ->
							for test in suite.tests
								do (test) ->
									fce = (done) ->
										try
											JSON.validate JSON.stringify(test.data), suite.schema
											result = true
										catch ex
											#console.error 'ERR', ex.message
											#console.error 'SUB', ex.suberrors
											result = false
										
										assert.strictEqual result, test.valid
										done()
									
									if test.only
										it.only test.description, fce
									else if test.skip
										it.skip test.description, fce
									else
										it test.description, fce

describe 'JSON Schema Test Suite', ->
	before (done) ->
		JSON.addSchema require "#{__dirname}/suite/remotes/integer.json"
		JSON.addSchema require "#{__dirname}/suite/remotes/subSchemas.json"
		JSON.loadRemoteSchema 'http://json-schema.org/draft-04/schema', done
	
	readDir "#{__dirname}/suite"
	readDir "#{__dirname}/suite/optional"