package toml;

// todo: setting should use tokens so we have positions for errors!

abstract TomlTable({}) from {} to {} {

  public function new(data) this = data;

  public function set(key:String, value:Dynamic) {
    if (Reflect.hasField(this, key)) {
      throw '[$key] cannot be redefined';
    }
    Reflect.setField(this, key, value);
  }

  public function setPath(path:Array<String>, value:Dynamic) {
    var key = path[ path.length - 1 ];
    var table:TomlTable = this;
    for (i in 0...(path.length - 1)) {
      var part = path[i];
      if (table.exists(part)) {
        table = table.get(part);
        if (!Reflect.isObject(table)) {
          throw 'Invalid key target';
        }
      } else {
        var prev = table;
        table = new TomlTable({});
        prev.set(part, table);
      }
    }
    table.set(key, value);
  }

  public function addToArray(path:Array<String>, value:Dynamic) {
    var arr = getPath(path);
    if (arr == null) {
      setPath(path, [ value ]);
      return;
    }
    if (Std.is(arr, Array)) {
      var target:Array<Dynamic> = cast arr;
      target.push(value);
    } else {
      throw 'Invalid array target';
    }
  }

  public function getPath(path:Array<String>) {
    var key:String = path[ path.length - 1 ];
    var table:TomlTable = this;
    for (i in 0...(path.length - 1)) {
      var part = path[i];
      table = table.get(part);
      if (table != null && !Reflect.isObject(table)) {
        throw 'Invalid key target';
      }
    }
    return table.get(key);
  }

  public function get(key:String) {
    return Reflect.field(this, key);
  }

  public function exists(key:String) {
    return Reflect.hasField(this, key);
  }

}
