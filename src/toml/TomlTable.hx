package toml;

// @todo: Setting should use tokens so we have positions for errors!
// @todo: This API is really confusing.
@:allow(toml.Parser)
abstract TomlTable({}) from {} to {} {

  public function new(data) this = data;

  function set(key:String, value:Dynamic) {
    if (Reflect.hasField(this, key)) {
      throw '[$key] cannot be redefined';
    }
    Reflect.setField(this, key, value);
  }

  function setPath(path:Array<String>, value:Dynamic) {
    var key = path[ path.length - 1 ];
    var table:TomlTable = this;
    for (i in 0...(path.length - 1)) {
      var part = path[i];
      if (table.exists(part)) {
        table = locate(part, table);
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

  function addToArray(path:Array<String>, value:TomlTable) {
    var arr = getPath(path);
    if (arr == null) {
      setPath(path, [ value ]);
      return;
    }
    if (Std.is(arr, Array)) {
      var target:Array<TomlTable> = cast arr;
      target.push(value);
    } else {
      throw 'Invalid array target';
    }
  }

  function getPath(path:Array<String>) {
    var key:String = path[ path.length - 1 ];
    var table:TomlTable = this;

    for (i in 0...(path.length - 1)) {
      var part = path[i];
      table = locate(part, table);
      if (table != null && !Reflect.isObject(table)) {
        throw 'Invalid key target';
      }
    }

    return table.get(key);
  }

  // Returns a table or the top table in an array.
  function locate(part:String, table:TomlTable):TomlTable {
    var item = table.get(part);
    if (Std.is(item, Array)) {
      var items:Array<TomlTable> = cast item;
      return items[items.length - 1];
    }
    return item;
  }

  function get(key:String) {
    return Reflect.field(this, key);
  }

  function exists(key:String) {
    return Reflect.hasField(this, key);
  }

}
