package toml;

using Reflect;

// Todo: catch errors and invalid values, be more robust with string generation.
class Generator {

  private var reporter:Reporter;
  private var data:Dynamic;

  public function new(data:Dynamic, ?reporter:Reporter) {
    this.data = data;
    this.reporter = reporter == null ? new DefaultReporter() : reporter;
  }

  public function generate():String {
    if (!data.isObject()) {
      reporter.error({ line: 0 }, 'Only objects may be generated');
      return '';
    }
    return genObject(null, data);
  }

  private function genObject(?name:String, obj:Dynamic):String {
    var body:Array<String> = [];
    var objects:Array<String> = [];
     
    for (key in obj.fields()) {
      var value:Dynamic = obj.field(key);
      if (Std.is(value, String) || Std.is(value, Array) || Std.is(value, Int)) {
        body.push(genStatement(key, value));
      } else {
        var path = name != null ? '$name.$key' : key;
        objects.push(genObject(path, value));
      }
    }
    
    if (objects.length > 0) {
      body.push(objects.join('\n'));
    }

    if (name != null) return '[$name]\n${body.join('\n')}';
    return body.join('\n');
  }

  private function genStatement(key:String, value:Dynamic):String {
    return '$key = ${genValue(value)}';
  }

  private function genValue(value:Dynamic):String {
    // todo: need to handle escaping
    if (Std.is(value, String)) {
      if ((value:String).indexOf('\n') > 0) return '"""${value}"""';
      return '"$value"';
    }
    if (Std.is(value, Array)) return genInlineArray(cast value);
    // todo: handle inline objects
    return value;
  }

  private function genInlineArray(values:Array<Dynamic>):String {
    return '[' + values.map(genValue).join(', ') + ']';
  }

}