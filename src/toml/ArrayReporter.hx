package toml;

class ArrayReporter implements Reporter {
  
  public var hadError(default, null):Bool = false;
  public var errors(default, null):Array<String> = [];

  public function new() {}

  public function error(token:{
    line:Int,
    ?lexeme:String,
    ?type:toml.TokenType
  }, message:String) {
    if (token.type == null) {
      report(token.line, '', message);
    } else if (token.type.equals(toml.TokenType.TokEof)) {
      report(token.line, " at end", message);
    } else {
      report(token.line, " at '" + token.lexeme + "'", message);
    }
  }
  
  private function report(line:Int, where:String, message:String) {
    errors.push('[line $line] Error${where}: ${message}');
    hadError = true;
  }

}
