# jsonv [![Dependency Status](https://david-dm.org/patriksimek/jsonv.png)](https://david-dm.org/patriksimek/jsonv) [![NPM version](https://badge.fury.io/js/jsonv.png)](http://badge.fury.io/js/jsonv) [![Build Status](https://secure.travis-ci.org/patriksimek/jsonv.png)](http://travis-ci.org/patriksimek/jsonv)

JSON Validator.

## Installation

    npm install jsonv

## Quick Example

```javascript
require('jsonv');
```

#### Synchronous validation

```javascript
try {
	parsed = JSON.validate('1', {type: 'integer'});
} catch (err) {
	console.log(err.message);
	console.log(err.suberrors); // Array of validation sub-errors.
}
```

#### Asynchronous validation

```javascript
JSON.validate('1', {type: 'integer'}, function(err, parsed) {
	if (err) {
		console.log(err.message);
		console.log(err.suberrors); // Array of validation sub-errors.
	}
});
```

## Documentation

### JSON.validate(document, schema, [options], [callback])

Validate JSON document and return parsed object.

__Arguments__

- **document** - A JSON string.
- **schema** - Validation schema. A JSON string or parsed structure.
- **options**
  - **maxLength** - Check maximum length of JSON string (default: `null`).
  - **followRefs** - Allow `$ref` keyword (JSON Pointer) in JSON document (default: `false`).
- **callback(err)** - A callback which is called after validation has ended, or an error has occurred. Optional.

__Errors__

If an errro occur, `JSONValidationError` is thrown. It has property `suberrors` that contains list of all validation errros.

---------------------------------------

### JSON.addSchema(schema)

Add schema to list of locally cached schemas. Each schema must have `$schema` header present.

__Arguments__

- **schema** - Validation schema. A JSON string or parsed structure.

---------------------------------------

### JSON.loadRemoteSchema(url, callback)

Load remote schema and add it to list of locally cached schemas. Each schema must have `$schema` header present.

__Arguments__

- **url** - URL address.
- **callback(err, schema)** - A callback which is called after loading has ended, or an error has occurred.

---------------------------------------

### Schema Structure

[Understanding JSON Schema](http://spacetelescope.github.io/understanding-json-schema/index.html)

<a name="license" />
## License

Copyright (c) 2014 Patrik Simek

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
