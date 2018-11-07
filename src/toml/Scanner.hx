package toml;

import toml.TokenType;

class Scanner {

  private var source:String;
  private var tokens:Array<Token> = [];
  private var start:Int = 0;
  private var current:Int = 0;
  private var line:Int = 1;
  private var reporter:Reporter;

  public function new(source:String, ?reporter:Reporter) {
    this.source = source;
    this.reporter = reporter == null ? new DefaultReporter() : reporter;
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
          reporter.error({ line: line }, 'Unexpected character: $c');
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

  // NOTE:
  // This is far from compliant with the way TOML handles
  // strings. Most importantly, single quote strings DO NOT
  // support escaping at all. We'll need to handle them differently. 
  private function string(lastChar:String) {
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
      reporter.error({ line: line }, 'Unterminated string.');
      return;
    }

    // The closing character
    advance();

    var value = source.substring(start + 1, current - 1);
    addToken(TokString, value);
  }

  // TODO:
  // We need to handle line-ending backslashes correctly.
  private function multilineString(lastChar:String) {
    while (!isAtEnd()) {
      if (match(lastChar) && match(lastChar) && match(lastChar)) {
        break;
      } else {
        if (peek() == '\n') {
          line++;
        }
        advance();
      }
    }

    if (isAtEnd()) {
      reporter.error({ line: line }, 'Unterminated string.');
      return;
    }

    var value = source.substring(start + 3, current - 3);
    addToken(TokString, StringTools.ltrim(value));
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

  // TODO:
  // Underscores are allowed here to help with visibility.
  // They are simply ignored.
  // To make this a bit more complicated, they are only valid 
  // between two numbers (eg, `5_100_200`, and not `12_00_`)
  //
  // We also need to handle hexadecimal, octal and binary prefixes.
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