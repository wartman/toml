package toml;

import haxe.Resource;

using Reflect;
using hex.unittest.assertion.Assert;

class TestParser {

  @Test
  public function testParsesHardExample() {
    var hard:{} = Toml.parse(Resource.getString('hard_example'));
    hard.field('the').field('test_string').equals("You'll hate me after this - #");
  
    var testArray:Array<String> = hard.field('the').field('hard').field('test_array');
    testArray.length.equals(2);
    testArray[0].equals('] ');
    testArray[1].equals(' # ');
  
    var bit:{} = hard.field('the').field('hard').field('bit#');
    bit.field('what?').equals("You don't think some user won't do that?");
    var testArray2:Array<String> = bit.field('multi_line_array');
    testArray2.length.equals(1);
    testArray2[0].equals(']');
  }

  @Test
  public function testMultilineString() {
    var data:{ foo:String } = Toml.parse('
      foo = """
        I am a big string.
        Yay.
      """
    ');
    data.foo.equals('I am a big string.
        Yay.
      ');

    data = Toml.parse("
      foo = '''
        I am also a big string.
        Yay.
      '''
    ");
    data.foo.equals('I am also a big string.
        Yay.
      ');
  }

  @Test
  public function testCommentError() {
    var reporter = new ArrayReporter();
    try {
      run('[error] forgot to comment', reporter);
    } catch(e:Parser.ParserError) {
      reporter.errors.length.equals(1);
      reporter.errors[0].equals("[line 1] Error at 'forgot': Expected a newline");
      return;
    }
    false.equals(true);
  }

  @Test
  public function testIncorrectArray() {
    var reporter = new ArrayReporter();
    try {
      run('
        array = [
          "This should,
          not work" 
          ]
      ', reporter);
    } catch(e:Parser.ParserError) {
      reporter.errors[0].equals('[line 3] Error: Unterminated string.');
      return;
    }
    false.equals(true);
  }

  @Test
  public function testParsingThatEndsWithoutNewline() {
    var pair:{} = Toml.parse('foo = "bar"');
    pair.field('foo').equals('bar');
  }

  private function run(input:String, reporter:Reporter) {
    var scanner = new Scanner(input, reporter);
    var parser = new Parser(scanner.scan(), reporter);
    return parser.parse();
  }

}