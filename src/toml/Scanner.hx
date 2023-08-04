package toml;

import toml.TokenType;

class Scanner {

  final source:String;
  var tokens:Array<Token> = [];
  var start:Int = 0;
  var current:Int = 0;
  var line:Int = 1;

  public function new(source:String) {
    this.source = source;
  }

  public function scan() {
    while (!isAtEnd()) {
      start = current;
      scanToken();
    }
    tokens.push(new Token(TokEof, '', null, line));
    return tokens;
  }

  function scanToken() {
    var c = advance();
    switch (c) {
      case '[': addToken(TokLeftBracket);
      case ']': addToken(TokRightBracket);
      case '{': addToken(TokLeftBrace);
      case '}': addToken(TokRightBrace);
      case '=': addToken(TokEqual);
      case ',': addToken(TokComma);
      case '-': addToken(TokDash);
      case '_': addToken(TokUnderline);
      case '#': comment();
      case '.': addToken(TokDot);
      case '"': string('"');
      case "'": string("'");
      case '\n': newline(); // Might be a valid statement end -- checked by the parser.
      case ' ' | '\r' | '\t': null; // ignore
      default: 
        if (isDigit(c)) {
          number();
        } else if (isAlpha(c)) {
          identifier();
        } else {
          throw new TomlError({ line: line }, 'Unexpected character: $c');
        }
    }
  }

  function comment() {
    while(peek() != '\n') advance();
  }

  function identifier() {
    while (isAlphaNumeric(peek()) || peek() == '-' || peek() == '_') advance();
    var text = source.substring(start, current);
    switch (text) {
      case 'true': addToken(TokTrue);
      case 'false': addToken(TokFalse);
      default: addToken(TokIdentifier);
    }
  }

  // NOTE:
  // This is far from compliant with the way TOML handles
  // strings. Most importantly, single quote strings DO NOT
  // support escaping at all. We'll need to handle them differently. 
  function string(lastChar:String) {
    if (match(lastChar)) {
      if (match(lastChar)) {
        multilineString(lastChar);
      } else {
        addToken(TokString, '');
      }
      return;
    } 

    while (peek() != lastChar && !isAtEnd() && peek() != '\n') {
      if (peek() == '\\') {
        // todo: actual escaping.
        advance();
        if (peek() == lastChar) advance();
      } else {
        advance();
      }
    }

    if (isAtEnd() || peek() == '\n') {
      throw new TomlError({ line: line }, 'Unterminated string.');
      return;
    }

    // The closing character
    advance();

    var value = source.substring(start + 1, current - 1);
    addToken(TokString, value);
  }

  // TODO:
  // We need to handle line-ending backslashes correctly.
  function multilineString(lastChar:String) {
    var isClosed = false;
    while (!isAtEnd()) {
      if (match(lastChar) && match(lastChar) && match(lastChar)) {
        isClosed = true;
        break;
      } else {
        if (peek() == '\n') {
          line++;
        }
        advance();
      }
    }

    if (!isClosed) {
      throw new TomlError({ line: line }, 'Unterminated string.');
      return;
    }

    var value = source.substring(start + 3, current - 3);
    addToken(TokString, StringTools.ltrim(value));
  }

  function newline() {
    line++;
    // todo: may need to handle windows newline too :P
    while (peek() == '\n' && !isAtEnd()) {
      line++;
      advance();
    }
    addToken(TokNewline);
  }

  // TODO:
  // Underscores are allowed here to help with visibility.
  // They are simply ignored.
  // To make this a bit more complicated, they are only valid 
  // between two numbers (eg, `5_100_200`, and not `12_00_`)
  //
  // We also need to handle hexadecimal, octal and binary prefixes.
  function number() {
    while(isDigit(peek())) advance();
    if (peek() == '.' && isDigit(peekAt(current + 1))) {
      advance();
      while (isDigit(peek())) advance();
    }
    addToken(TokNumber, Std.parseFloat(source.substring(start, current)));
  }
  
  function isAtEnd():Bool {
    return current >= source.length;
  }

  function isDigit(c:String):Bool {
    return c >= '0' && c <= '9';
  }

  function isAlpha(c:String):Bool {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
            c == '_';
  }

  function isAlphaNumeric(c:String) {
    return isAlpha(c) || isDigit(c);
  }

  function match(expected:String):Bool {
    if (isAtEnd()) {
      return false;
    }
    if (source.charAt(current) != expected) {
      return false;
    }
    current++;
    return true;
  }

  function peek():String {
    if (isAtEnd()) {
      return '';
    }
    return source.charAt(current);
  }

  function peekAt(i) {
    if (i >= source.length) {
      return '';
    }
    return source.charAt(i);
  }

  function advance() {
    current++;
    return source.charAt(current - 1);
  }

  function addToken(type:TokenType, ?literal:Dynamic) {
    var text = source.substring(start, current);
    tokens.push(new Token(type, text, literal, line));
  }

}