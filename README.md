ParsedEmail
===========

Email parser that returns a Parsed Email Object.


Usage:

myParsedEmailObject = ParsedEmail.new("file/path")

This will parse out an email and return a parsed email object that has the following structure:

myParsedEmailObject.headers  //This is a dictionary that holds HeaderField : Header Value.

myParsedEmailObject.body // This will be used if the email has boundaries else content will be used.
the object structure of body looks like this

myParsedEmailObject.body.boundaries[0].sections[0] each section contains headers and content
//myParsedEmailObject.body.boundaries[0].sections[0].headers would give you the headers for the first section in the first boundary found.

myParsedEmailObject.content is used if this email is a non boundaried text/plain email and will store the email content in here otherwise it will be blank.
