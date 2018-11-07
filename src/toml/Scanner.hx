package toml;

import toml.TokenType;

class Scanner {

  private var source:String;
  private var tokens:Array<Token> = [];
  private var start:Int = 0;
  private var current:Int = 0;
  private var line:Int = 1;

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

  private function scanToken() {
    var c = advance();
    switch (c) {
      case '[': addToken(TokLeftBracket);
      case ']': addToken(TokRightBracket);
      case '{': addToken(TokLeftBrace);
      case '}': addToken(TokRightBrace);
      case '=': addToken(TokEqual);
      case ',': addToken(TokComma);
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
          Toml.error({ line: line }, 'Unexpected character: $c');
        }
    }
  }

  private function comment() {
    while(peek() != '\n') advance();
  }

  private function identifier() {
    while (isAlphaNumeric(peek())) advance();
    var text = source.substring(start, current);
    switch (text) {
      case 'true': addToken(TokTrue);
      case 'false': addToken(TokFalse);
      default: addToken(TokIdentifier);
    }
  }

  private function string(lastChar:String) {
    if (match(lastChar)) {
      if (match(lastChar)) {
        multilineString(lastChar);
      } else {
        addToken(TokString, '');
      }
      return;
    } 

    while (peek() != lastChar && !isAtEnd()) {
      if (peek() == '\n') {
        line++;
      }
      if (peek() == '\\') {
        advance();
        if (peek() == lastChar) advance();
      } else {
        advance();
      }
    }
    if (isAtEnd()) {
      Toml.error({ line: line }, 'Unterminated string.');
      return;
    }

    // The closing character
    advance();

    var value = source.substring(start + 1, current - 1);
    addToken(TokString, value);
  }

  private function multilineString(lastChar:String) {
    while (!isAtEnd()) {
      if (match(lastChar) && match(lastChar) && match(lastChar)) {
        break;
      } else {
        advance();
      }
    }

    if (isAtEnd()) {
      Toml.error({ line: line }, 'Unterminated string.');
      return;
    }

    var value = source.substring(start + 3, current - 3);
    addToken(TokString, value);
  }

  private function newline() {
    line++;
    // todo: may need to handle windows newline too :P
    while (peek() == '\n' && !isAtEnd()) {
      line++;
      advance();
    }
    addToken(TokNewline);
  }

  private function number() {
    while(isDigit(peek())) advance();
    if (peek() == '.' && isDigit(peekAt(current + 1))) {
      advance();
      while (isDigit(peek())) advance();
    }
    addToken(TokNumber, Std.parseFloat(source.substring(start, current)));
  }
  
  private function isAtEnd():Bool {
    return current >= source.length;
  }

  private function isDigit(c:String):Bool {
    return c >= '0' && c <= '9';
  }

  private function isAlpha(c:String):Bool {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
            c == '_';
  }

  private function isAlphaNumeric(c:String) {
    return isAlpha(c) || isDigit(c);
  }

  private function match(expected:String):Bool {
    if (isAtEnd()) {
      return false;
    }
    if (source.charAt(current) != expected) {
      return false;
    }
    current++;
    return true;
  }

  private function peek():String {
    if (isAtEnd()) {
      return '';
    }
    return source.charAt(current);
  }

  private function peekAt(i) {
    if (i >= source.length) {
      return '';
    }
    return source.charAt(i);
  }

  private function advance() {
    current++;
    return source.charAt(current - 1);
  }

  private function addToken(type:TokenType, ?literal:Dynamic) {
    var text = source.substring(start, current);
    tokens.push(new Token(type, text, literal, line));
  }

}