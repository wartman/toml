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

}
