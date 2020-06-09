package toml;

typedef TokenDef = {
  @:optional public var type:TokenType;
  @:optional public var lexeme:String;
  @:optional public var literal:Dynamic;
  @:optional public var line:Int;
}

@:forward
abstract Token(TokenDef) from TokenDef to TokenDef {

  inline public function new(type:TokenType, lexeme:String, literal:Dynamic, line:Int) {
    this = {
      type: type,
      lexeme: lexeme,
      literal: literal,
      line: line
    };
  }

  inline public function toString():String {
    return '${Std.string(this.type)} ${this.lexeme} ${Std.string(this.literal)}';
  }

}
