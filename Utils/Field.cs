// 2026-04-24 21:45:09

namespace WebAPI.Utils {
    namespace UMSystem {
        #region

        using System.Collections.Concurrent;
        using System.Globalization;
        using Tomlyn;
        using Tomlyn.Model;

        #endregion

        public enum EventType {
            ValueChange,
            ValueLoad,
        }

        public abstract class FieldEntryBase(string name, Type type) {
            public readonly ReaderWriterLockSlim ValueLock = new();

            public bool IsChanged;

            public string Name { get; } = name;
            public Type Type { get; } = type;

            public event Action<FieldEntryBase, EventType>? Event;

            public abstract object encode();

            public abstract void decode(object value);

            protected void fire(EventType e) {
                this.Event?.Invoke(this, e);
            }
        }

        public class FieldEntry<T>(string name, T value) : FieldEntryBase(name, typeof(T)) {
            public T Value = value;

            public override object encode() {
                this.ValueLock.EnterReadLock();
                try {
                    return this.Value!;
                } finally {
                    this.ValueLock.ExitReadLock();
                }
            }

            public override void decode(object value) {
                this.ValueLock.EnterWriteLock();
                try {
                    if (value is T v) {
                        this.Value = v;
                    } else {
                        this.Value = (T)Convert.ChangeType(value, typeof(T), CultureInfo.InvariantCulture);
                    }
                } finally {
                    this.ValueLock.ExitWriteLock();
                }

                this.fire(EventType.ValueLoad);
            }

            public void notify_change() {
                this.IsChanged = true;
                this.fire(EventType.ValueChange);
            }
        }

        public static class Config {
            static readonly ConcurrentDictionary<string, FieldEntryBase> Fields = new();

            static TomlTable _config = new();

            static string _path = "";

            static string[] split(string name) => name.Split("::", StringSplitOptions.RemoveEmptyEntries);

            static bool try_get(TomlTable root, string name, out object value) {
                string[] parts = Config.split(name);

                object node = root;

                foreach (string p in parts) {
                    if (node is TomlTable tbl && tbl.TryGetValue(p, out node)) {
                        continue;
                    }
                    value = null!;
                    return false;
                }

                value = node;
                return true;
            }

            static void set(TomlTable root, string name, object value) {
                string[] parts = Config.split(name);

                TomlTable node = root;

                for (var i = 0; i < parts.Length; i++) {
                    string p = parts[i];

                    if (i == (parts.Length - 1)) {
                        node[p] = value;
                        return;
                    }

                    if (!node.TryGetValue(p, out object next) || next is not TomlTable tbl) {
                        tbl = new();
                        node[p] = tbl;
                    }

                    node = tbl;
                }
            }

            public static FieldEntry<T> find_or_create<T>(string name, T defaultValue) {
                if (Config.Fields.TryGetValue(name, out FieldEntryBase? entry)) {
                    return entry is not FieldEntry<T> e ? throw new("Type mismatch") : e;
                }

                var new_entry = new FieldEntry<T>(name, defaultValue);

                Config.Fields[name] = new_entry;

                if (Config.try_get(Config._config, name, out object v)) {
                    new_entry.decode(v);
                }

                return new_entry;
            }

            public static void load(string file) {
                Config._path = file;

                if (!File.Exists(file)) {
                    string? dir = Path.GetDirectoryName(file);
                    if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) {
                        Directory.CreateDirectory(dir);
                    }
                    File.WriteAllText(file, "");
                    Config._config = new();
                    return;
                }

                string text = File.ReadAllText(file);

                Config._config = TomlSerializer.Deserialize<TomlTable>(text)!;

                foreach (KeyValuePair<string, FieldEntryBase> kv in Config.Fields) {
                    if (Config.try_get(Config._config, kv.Key, out object v)) {
                        kv.Value.decode(v);
                    }
                }
            }

            public static void save() {
                if (string.IsNullOrEmpty(Config._path)) {
                    throw new InvalidOperationException("Config path not set. Call load(path) first.");
                }

                string? dir = Path.GetDirectoryName(Config._path);
                if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) {
                    Directory.CreateDirectory(dir);
                }

                foreach (KeyValuePair<string, FieldEntryBase> kv in Config.Fields) {
                    Config.set(Config._config, kv.Key, kv.Value.encode());
                    kv.Value.IsChanged = false;
                }

                File.WriteAllText(Config._path, TomlSerializer.Serialize(Config._config));
            }
        }

        public class Field<T>(string name, T defaultValue = default!) {
            readonly FieldEntry<T> _entry = Config.find_or_create(name, defaultValue);

            public T Value {
                get {
                    this._entry.ValueLock.EnterReadLock();
                    try {
                        return this._entry.Value;
                    } finally {
                        this._entry.ValueLock.ExitReadLock();
                    }
                }
                set {
                    this._entry.ValueLock.EnterWriteLock();
                    try {
                        this._entry.Value = value;
                        this._entry.notify_change();
                    } finally {
                        this._entry.ValueLock.ExitWriteLock();
                    }
                }
            }

            public event Action<FieldEntryBase, EventType>? Event {
                add => this._entry.Event += value;
                remove => this._entry.Event -= value;
            }

            public static implicit operator T(Field<T> f) => f.Value;

            public static implicit operator Field<T>((Field<T> field, T value) tuple) {
                tuple.field.Value = tuple.value;
                return tuple.field;
            }
        }
    }
}
