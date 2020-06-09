package toml;

import toml.TokenType;

class Parser {

  private var tokens:Array<Token>;
  private var table:TomlTable;
  private var current:Int = 0;
  private var reporter:Reporter;

  public function new(tokens:Array<Token>, ?reporter:Reporter) {
    this.tokens = tokens;
    this.reporter = reporter == null ? new DefaultReporter() : reporter;
  }

  public function parse():TomlTable {
    table = new TomlTable({});
    ignoreNewlines();
    while (!isAtEnd()) parseStatement();
    return table;
  }

  private function parseStatement() {
    if (check(TokString) || check(TokIdentifier)) {
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
    var path = parseKeyPath();
    consume(TokEqual, 'Expect an equals');
    table.setPath(path, parseValue());
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

    path.push(getStringOrIdent());
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

    // todo: parse inline tables!
    if (match([ TokIdentifier, TokString ])) return previous().literal;
    
    if (match([ TokNumber ])) {
      var number = previous();
      if (match([ TokDash ])) {
        // todo: The rest of this spec: https://github.com/toml-lang/toml#user-content-offset-date-time
        //       Currently this only covers `Local Date`

        var month = consume(TokNumber, 'Expected a month');
        consume(TokDash, 'Expected a dash after the month');
        var day = consume(TokNumber, 'Expected a day');

        function formatNumber(num:Int) {
          var str = Std.string(num);
          if (str.length == 1) return '0${str}';
          return str;
        }

        return Date.fromString('${number.literal}-${formatNumber(month.literal)}-${formatNumber(day.literal)}');
      }
      return Std.int(number.literal);
    }

    if (match([ TokFalse ])) return false;

    if (match([ TokTrue ])) return true;

    error(advance(), 'Expected a number, integer, string or datetime');
    
    return null;
  }

  private function ignoreNewlines() {
    if (check(TokNewline)) newline();
  }

  private function newline() {
    if (isAtEnd()) return;
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
    reporter.error(token, message);
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

