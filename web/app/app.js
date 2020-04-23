var express = require("express");
var app = express();
const port = 3000
app.listen(port, () => console.log(`Listening on port ${port}`));

var bodyParser = require("body-parser");
app.use(bodyParser.urlencoded({ extended: false }));

// Get index page
app.get('/', function (req, res) {
  res.sendFile(__dirname + '/index.html');
});


// curl localhost:3000/wordInput
app.get("/:wordInput", (req, res, next) => {
  let checkWord = req.params.wordInput;
  const wordList = checkWordlist(checkWord);
  console.log(`${req.params.wordInput}`);
  res.json(JSON.stringify(wordList));
});

// http://localhost:3000
app.post('/', function(req, res){
  let checkWord = req.body.wordInput;
  const wordList = checkWordlist(checkWord);
  console.log(`${req.body.wordInput}`);
  var html = '<b>Your Anagrams:</b> ' + wordList + '<br>' + '<a href="/">Try again!</a>';
  res.send(html);
});

// Read word list
var fs = require("fs");
const path = require("path");
fs.readFile(
  path.resolve(__dirname, "./webster.txt"),
  "utf8",
  (err, contents) => {
    if (err) {
      throw err;
    }
    websterList = contents.split("\n");
  }
);

// Check user input against word list
const checkWordlist = (inputString, wordList = websterList) => {
  const results = [];
  for (var i = 0; i < wordList.length; i++) {
    const word = wordList[i];
    let inputCopy = inputString;
    let wordMatch = true;
    for (var x = 0; x < word.length; x++) {
      const item = word[x];
      const currentWord = inputCopy.indexOf(item);
      if (currentWord > -1) {
        inputCopy = (inputCopy.substring(0, currentWord) + inputCopy.substring(currentWord + 1, inputCopy.length));
        } else {
          wordMatch = false;
      }
    }
    if (wordMatch) {
      results.push(word);
    }
  }
  return results;

};