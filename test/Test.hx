import medic.Runner; 
import toml.*;

class Test {

  public static function main() {
    var runner = new Runner();
    runner.add(new TestParser());
    runner.add(new TestGenerator());
    runner.run();
  }

}
