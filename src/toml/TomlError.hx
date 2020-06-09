package toml;

// @todo: add file offsets and other things somewhere.
class TomlError {

  final token:Token.TokenDef;
  final message:String;

  public function new(token, message) {
    this.token = token;
    this.message = message;
  }

  public function toString() {
    return if (token.type == null) {
      report(token.line, '', message);
    } else if (token.type.equals(toml.TokenType.TokEof)) {
      report(token.line, " at end", message);
    } else {
      report(token.line, " at '" + token.lexeme + "'", message);
    }
  }
  
  function report(line:Int, where:String, message:String) {
    return '[line $line] Error${where}: ${message}';
  }

}

