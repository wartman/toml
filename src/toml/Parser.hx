package toml;

import toml.TokenType;

class Parser {

  final tokens:Array<Token>;
  var table:TomlTable;
  var current:Int = 0;

  public function new(tokens:Array<Token>) {
    this.tokens = tokens;
  }

  public function parse():TomlTable {
    table = new TomlTable({});
    ignoreNewlines();
    while (!isAtEnd()) parseStatement();
    return table;
  }

  function parseStatement() {
    if (check(TokString) || check(TokIdentifier)) {
      parsePair();
      newline();
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

  function parsePair() {
    var path = parseKeyPath();
    consume(TokEqual, 'Expect an equals');
    table.setPath(path, parseValue());
  }

  function parseTable() {
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

  function parseArrayOfTables() {
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

  function parseKeyPath():Array<String> {
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

  function parseInlineTable() {
    var prevTable = table;
    table = new TomlTable({});
    do {
      if (match([ TokNewline ])) {
        throw error(previous(), 'Newlines are not allowed in inine tables');
      } 
      parsePair();
    } while (!isAtEnd() && match([ TokComma ]));
    consume(TokRightBrace, 'Expected an ending }');
    var value = table;
    table = prevTable;
    return value;
  }

  function parseInlineArray() {
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

  function parseDate(year:Token) {
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

    return Date.fromString('${year.literal}-${formatNumber(month.literal)}-${formatNumber(day.literal)}');
  }

  function parseValue():Dynamic {
    if (match([ TokLeftBracket ])) return parseInlineArray();
    if (match([ TokLeftBrace ])) return parseInlineTable();
    if (match([ TokIdentifier, TokString ])) return previous().literal;
    if (match([ TokNumber ])) {
      var number = previous();
      if (match([ TokDash ])) return parseDate(number);
      return Std.int(number.literal);
    }
    if (match([ TokFalse ])) return false;
    if (match([ TokTrue ])) return true;
    throw error(advance(), 'Expected a number, integer, string or datetime');
  }

  function ignoreNewlines() {
    if (check(TokNewline)) newline();
  }

  function newline() {
    if (isAtEnd()) return;
    consume(TokNewline, 'Expected a newline');
    while(check(TokNewline) && !isAtEnd()) advance();
  }

  function whitespace() {
    while (!check(TokNewline) && !isAtEnd()) advance();
  }

  function match(types:Array<TokenType>):Bool {
    for (type in types) {
      if (check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  function consume(type:TokenType, message:String) {
    if (check(type)) return advance();
    throw error(peek(), message);
  } 

  function check(type:TokenType):Bool {
    if (isAtEnd()) return false;
    return peek().type.equals(type);
  }

  function advance():Token {
    if (!isAtEnd()) current++;
    return previous();
  }

  function isAtEnd() {
    return peek().type.equals(TokEof);
  }

  function peek():Token {
    return tokens[current];
  }

  function previous():Token {
    return tokens[current - 1];
  }

  function error(token:Token, message:String) {
    return new TomlError(token, message);
  }

}