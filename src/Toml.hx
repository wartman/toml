import haxe.DynamicAccess;

class Toml {

  public static var hadError:Bool = false;

  public static function parse(data:String):Dynamic {
    var tokens = new toml.Scanner(data).scan();
    return new toml.Parser(tokens).parse();
  }

  public static function generate(data:Dynamic):String {
    return new toml.Generator(data).generate();
  }

}
