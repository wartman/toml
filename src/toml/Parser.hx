package toml;

import toml.TokenType;

class Parser {

  private var tokens:Array<Token>;
  private var table:TomlTable;
  private var current:Int = 0;

  public function new(tokens:Array<Token>) {
    this.tokens = tokens;
  }

  public function parse():TomlTable {
    table = new TomlTable({});
    ignoreNewlines();
    while (!isAtEnd()) parseStatement();
    return table;
  }

  private function parseStatement() {
    if (match([ TokString, TokIdentifier ])) {
      parsePair();
    } else if (match([ TokLeftBracket ])) {
      if (match([ TokLeftBracket ])) {
        parseArrayOfTables();
      } else {
        parseTable();
      } 
    } else {
      throw error(advance(), 'Unexpected token');
    }
  }

  private function parsePair() {
    var path = parseKeyPath(previous().lexeme);
    consume(TokEqual, 'Expect an equals');
    table.setPath(path, parseValue());    
    // todo: parse inline tables!
    newline();
  }

  private function parseTable() {
    var path = parseKeyPath();
    consume(TokRightBracket, 'Expected a right bracket');
    newline();

    var prevTable = table;
    table = new TomlTable({});

    while (!isAtEnd()) {
      if (check(TokLeftBracket)) break;
      parseStatement();
    }

    prevTable.setPath(path, table);
    table = prevTable;
  }

  private function parseArrayOfTables() {
    var path = parseKeyPath();
    consume(TokRightBracket, 'Expected a right bracket');
    consume(TokRightBracket, 'Expected a right bracket');
    newline();

    var prevTable = table;
    table = new TomlTable({});

    while (!isAtEnd()) {
      if (check(TokLeftBracket)) break;
      parseStatement();
    }

    prevTable.addToArray(path, table);
    table = prevTable;
  }

  private function parseKeyPath(?init:String):Array<String> {
    var path:Array<String> = [];

    function getStringOrIdent() {
      if (check(TokString)) {
        advance();
        return previous().literal;
      } else {
        consume(TokIdentifier, 'Expected a string or an identifier');
        return previous().lexeme;
      }
    }

    if (init != null) {
      path.push(init);
    } else {
      path.push(getStringOrIdent());
    }

    while(match([ TokDot ])) {  
      path.push(getStringOrIdent());
    }

    return path;
  }

  private function parseValue():Dynamic {
    if (match([ TokLeftBracket ])) {
      ignoreNewlines();
      var values = [ parseValue() ];
      ignoreNewlines();
      while (match([ TokComma ])) {
        ignoreNewlines();
        if (match([ TokRightBracket ])) {
          // allow trailing commas
          return values;
        }
        values.push(parseValue());
        ignoreNewlines();
      }
      ignoreNewlines();
      consume(TokRightBracket, 'Expected a right bracket');  
      return values;
    }


    if (match([ TokIdentifier, TokString ])) return previous().literal;
    if (match([ TokNumber ])) return Std.int(previous().literal);
    if (match([ TokFalse ])) return false;
    if (match([ TokTrue ])) return true;
    // todo: datetime
    error(advance(), 'Expected a number, integer, string or datetime');
    return null;
  }

  private function ignoreNewlines() {
    if (check(TokNewline)) newline();
  }

  private function newline() {
    consume(TokNewline, 'Expected a newline');
    while(check(TokNewline) && !isAtEnd()) advance();
  }

  private function whitespace() {
    while (!check(TokNewline) && !isAtEnd()) advance();
  }

  private function match(types:Array<TokenType>):Bool {
    for (type in types) {
      if (check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  private function consume(type:TokenType, message:String) {
    if (check(type)) return advance();
    throw error(peek(), message);
  } 

  private function check(type:TokenType):Bool {
    if (isAtEnd()) return false;
    return peek().type.equals(type);
  }

  private function advance():Token {
    if (!isAtEnd()) current++;
    return previous();
  }

  private function isAtEnd() {
    return peek().type.equals(TokEof);
  }

  private function peek():Token {
    return tokens[current];
  }

  private function previous():Token {
    return tokens[current - 1];
  }

  private function error(token:Token, message:String) {
    Toml.error(token, message);
    return new ParserError(message);
  }

}

class ParserError {

  private final message:String;

  public function new(message:String) {
    this.message = message;
  }

  public function toString() {
    return message;
  }

}

