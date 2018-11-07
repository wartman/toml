import haxe.DynamicAccess;

class Toml {

  public static var hadError:Bool = false;

  public static function parse(data:String):DynamicAccess<Dynamic> {
    var tokens = new toml.Scanner(data).scan();
    return new toml.Parser(tokens).parse();
  }

  public static function error(token:{
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
  
  private static function report(line:Int, where:String, message:String) {
    #if sys
      Sys.println('[line $line] Error${where}: ${message}');
    #else
      trace('[line $line] Error${where}: ${message}');
    #end
    hadError = true;
  }
}
