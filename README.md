# Gïelese

An open source language learning app and web app for South Sámi.

# So far... 

 * http://brunch.io/
   (version 1.4.4)
 * http://jquerymobile.com/
 * http://backbonejs.com/
 * http://www.schillmania.com/projects/soundmanager2/

Other dependencies should be stored in node package.json

# Things working

## Database

Uses `Concept` to create linked words, text and sound for producing translation
exercizes automatically. `Concepts` are also marked with either phonetic or
visual characteristics to link together visually and phonetically similar
answers, to create more challenging question sets.

`Question` defines the type of things that should be produced for users, can eitehr
be manually defined or automatically.

# Developing

Requires `node.js` and `npm` for the client side frontend. All other files
should be included. After installing node and npm...

    cd sma-client
    npm install

## Flask media server

Use virtualenv, install from requirements.txt and run the main python file.

## Development watching for brunch

Since this uses brunch, the easiest way to develop is:

    brunch watch

## License

Not yet decided.
