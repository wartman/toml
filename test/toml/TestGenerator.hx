package toml;

using medic.Assert;

class TestGenerator {
  
  public function new() {}

  @test
  public function testSimpleGeneration() {
    var toml = Toml.generate({ a:'a', b:'b' });
    toml.equals('a = "a"\nb = "b"');
  }

  @test
  public function testObjects() {
    var toml = Toml.generate({
      foo: {
        a: 'a',
        b: 'b'
      },
      bar: {
        a: 'a',
        b: 'b'
      } 
    });
    toml.equals('[foo]\na = "a"\nb = "b"\n[bar]\na = "a"\nb = "b"');
  }

  @test
  public function testNestedObjects() {
    var toml = Toml.generate({
      foo: {
        bar: {
          a: 'a',
          b: 'b',
          bin: { c: 'c' }
        },
        a: 'a'
      }
    });
    toml.equals('[foo]\na = "a"\n[foo.bar]\na = "a"\nb = "b"\n[foo.bar.bin]\nc = "c"');
  }

  @test
  public function inlineArrays() {
    var toml = Toml.generate({
      data: [ 1, 2, 3 ],
      data2: [ "one", "two", "three" ]
    });
    toml.equals('data = [1, 2, 3]\ndata2 = ["one", "two", "three"]');
  }

  @test
  public function testMultilineString() {
    var toml = Toml.generate({
      a: "
        foo
        ---
        bar
      "
    });
    toml.equals('a = """
        foo
        ---
        bar
      """');
  }

  @test
  public function ensureGeneratedTomlIsParseable() {
    var toml = Toml.generate({
      foo: {
        bar: {
          a: 'a',
          b: 'b',
          bin: { c: 'foo
          ---
          bar' }
        }
      }
    });
    var data:{ foo: { bar: { a:String, b:String, bin:{ c:String } } } } = Toml.parse(toml);
    data.foo.bar.a.equals('a');
    data.foo.bar.b.equals('b');
    data.foo.bar.bin.c.equals('foo
          ---
          bar');
  }

}
