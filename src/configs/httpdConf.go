package configs

import (
	"fmt"
)

type kvops []map[string]string

func KVOptions(o interface{}) (str string) {
	//DEBUG(reflect.TypeOf(kv), ".................",kv)

	for k, v := range o.(map[interface{}]interface{}) {
		str += fmt.Sprintf("\n%v\t%v", k, v)
	}
	return str
}

type dir struct {
	path    string
	options kvops
}

func Dirs(d []interface{}) (str string) {
	for _, v := range d {
		if mv, ok := v.(map[interface{}]interface{}); ok {
			str += fmt.Sprintf("\n<Directory %v>", mv["path"])
			if mo, ok := mv["options"]; ok {
				for k, v := range mo.(map[interface{}]interface{}) {
					str += fmt.Sprintf("\n\t%v\t%v", k, v)
				}
			}
			str += "\n</Directory>"
		}

	}
	return str
}
