package toml;

import haxe.Resource;

using Reflect;
using Medic;

class TestParser implements TestCase {

  public function new() {}

  @:test
  public function testParsesHardExample() {
    var hard:{} = Toml.parse(Resource.getString('hard_example'));
    (hard.field('the').field('test_string'):String).equals("You'll hate me after this - #");
  
    var testArray:Array<String> = hard.field('the').field('hard').field('test_array');
    testArray.length.equals(2);
    testArray[0].equals('] ');
    testArray[1].equals(' # ');
  
    var bit:{} = hard.field('the').field('hard').field('bit#');
    (bit.field('what?'):String).equals("You don't think some user won't do that?");
    var testArray2:Array<String> = bit.field('multi_line_array');
    testArray2.length.equals(1);
    testArray2[0].equals(']');
  }

  @:test
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

  @:test
  public function dottedIdentifier() {
    var data:{ foo: { bar:String } } = Toml.parse('
      foo.bar = "bin"
    ');
    data.foo.bar.equals('bin');
  }

  @:test
  public function dottedIdentifierInTable() {
    var data:{ foo: { bar:{  bin:String } } } = Toml.parse('
      [foo]
      bar.bin = "bin"
    ');
    data.foo.bar.bin.equals('bin');
  }

  @:test
  public function dottedIdentifierInDottedTable() {
    var data:{ foo: { thing:{ bar:{  bin:String } } } } = Toml.parse('
      [foo.thing]
      bar.bin = "bin"
    ');
    data.foo.thing.bar.bin.equals('bin');
  }

  @:test
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

  @:test
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

  @:test
  public function testParsingThatEndsWithoutNewline() {
    var pair:{} = Toml.parse('foo = "bar"');
    (pair.field('foo'):String).equals('bar');
  }

  @:test
  public function testParsingArrayOfTables() {
    var items:{} = cast Toml.parse('
      [[foo]]
      bar = "one"
      [[foo]]
      bar = "two"
    ');
    var foos:Array<Dynamic> = cast items.field('foo');
    foos.length.equals(2);
    (foos[0].field('bar'):String).equals('one');
    (foos[1].field('bar'):String).equals('two');
  }

  @:test
  public function testParsingArrayOfDottedTables() {
    var items:{} = cast Toml.parse('
      [[foo.bin]]
      bar = "one"
      [[foo.bin]]
      bar = "two"
    ');
    var bins:Array<Dynamic> = cast items.field('foo').field('bin');
    bins.length.equals(2);
    (bins[0].field('bar'):String).equals('one');
    (bins[1].field('bar'):String).equals('two');
  }

  @:test
  public function testParsingArrayOfDottedTablesWithDottedIdentifiers() {
    var items:{} = cast Toml.parse('
      [[foo.bin]]
      bar.bin = "one"
      [[foo.bin]]
      bar.bin = "two"
    ');
    var bins:Array<Dynamic> = cast items.field('foo').field('bin');
    bins.length.equals(2);
    (bins[0].field('bar').field('bin'):String).equals('one');
    (bins[1].field('bar').field('bin'):String).equals('two');
  }

  @:test
  public function testLocalDate() {
    var items:{ date:Date } = cast Toml.parse('
      date = 2020-06-24
    ');
    items.date.toString().equals('2020-06-24 00:00:00');
  }

  private function run(input:String, reporter:Reporter) {
    var scanner = new Scanner(input, reporter);
    var parser = new Parser(scanner.scan(), reporter);
    return parser.parse();
  }

}
