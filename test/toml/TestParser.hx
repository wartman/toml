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
    try {
      run('[error] forgot to comment');
    } catch(e:TomlError) {
      e.toString().equals("[line 1] Error at 'forgot': Expected a newline");
    }
  }

  @:test
  public function testIncorrectArray() {
    try {
      run('
        array = [
          "This should,
          not work" 
          ]
      ');
    } catch(e:TomlError) {
      e.toString().equals('[line 3] Error: Unterminated string.');
    }
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
    var items:{ foo:{ bin:Array<{ bar:String }> } } = cast Toml.parse('
      [[foo.bin]]
      bar = "one"
      [[foo.bin]]
      bar = "two"
    ');
    var bins = items.foo.bin;
    bins.length.equals(2);
    bins[0].bar.equals('one');
    bins[1].bar.equals('two');
  }

  @:test
  public function testParsingNestedArrayOfDottedTables() {
    var items:{ foo:Array<{ title:String, bin:Array<{ bar:String }> }> } = cast Toml.parse('
      [[foo]]
        title = "first"
        [[foo.bin]]
          bar = "one"
      
      [[foo]]
        title = "second"
        [[foo.bin]]
          bar = "two"
    ');
    items.foo.length.equals(2);
    items.foo[0].title.equals('first');
    items.foo[0].bin.length.equals(1);
    items.foo[0].bin[0].bar.equals('one');
    items.foo[1].bin.length.equals(1);
    items.foo[1].bin[0].bar.equals('two');
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

  // @todo: Test other dates.

  @:test
  public function parseInlineTable() {
    var items:{ foo: { a:String, b:String } } = cast Toml.parse("
      foo = { a = 'foo', b = 'bar' }
    ");
    items.foo.a.equals('foo');
    items.foo.b.equals('bar');
  }

  @:test
  public function inlineTableNoNewline() {
    try {
      Toml.parse("
        foo = { a = 'foo', 
        b = 'bar' }
      ");
    } catch (e:TomlError) {
      e.toString().equals("[line 3] Error at '\n': Newlines are not allowed in inine tables");
    } 
  }

  private function run(input:String) {
    var scanner = new Scanner(input);
    var parser = new Parser(scanner.scan());
    return parser.parse();
  }

}
