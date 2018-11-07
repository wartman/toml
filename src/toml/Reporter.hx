package toml;

interface Reporter {

  public function error(token:{
    line:Int,
    ?lexeme:String,
    ?type:TokenType
  }, message:String):Void;

}
