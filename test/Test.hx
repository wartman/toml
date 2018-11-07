import haxe.Resource;

class Test {

  public static function main() {
    var hard = Toml.parse(Resource.getString('hard_example'));
    trace(hard);
  }

}
