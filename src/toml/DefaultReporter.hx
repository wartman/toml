package toml;

class DefaultReporter implements Reporter {
  
  public var hadError(default, null):Bool = false;

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
    #if sys
      Sys.println('[line $line] Error${where}: ${message}');
    #else
      trace('[line $line] Error${where}: ${message}');
    #end
    hadError = true;
  }

}
