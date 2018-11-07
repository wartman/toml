import hex.unittest.notifier.*;
import hex.unittest.runner.*;
import toml.TestParser;

class Test {

  public static function main() {
    var emu = new ExMachinaUnitCore();
    emu.addListener(new ConsoleNotifier(false));
    emu.addListener(new ExitingNotifier());
    emu.addTest(TestParser);
    emu.run();
  }

}
