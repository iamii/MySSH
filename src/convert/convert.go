package convert

import (
	"fmt"
	"github.com/yuin/gopher-lua"
)

//参考:https://github.com/yuin/gluamapper/blob/master/gluamapper.go
func Lua2goValue(lv lua.LValue) interface{} {
	switch v := lv.(type) {
	case *lua.LNilType:
		return nil
	case lua.LBool:
		return bool(v)
	case lua.LString:
		return string(v)
	case lua.LNumber:
		return float64(v)
	case *lua.LTable:
		maxn := v.MaxN()
		if maxn == 0 { // table
			ret := make(map[interface{}]interface{})
			v.ForEach(func(key, value lua.LValue) {
				keystr := Lua2goValue(key)
				ret[keystr] = Lua2goValue(value)
			})
			return ret
		} else { // array
			ret := make([]interface{}, 0, maxn)
			for i := 1; i <= maxn; i++ {
				ret = append(ret, Lua2goValue(v.RawGetInt(i)))
			}
			return ret
		}
	default:
		return v
	}
}

func ConverToMsi(src interface{}) (dst interface{}, err error) {
	//DEBUG(reflect.TypeOf(src), "::::::::", src)
	switch rv := src.(type) {
	case map[interface{}]interface{}:
		tMsi := make(map[string]interface{})
		for k, v := range rv {
			if sk, ok := k.(string); ok {
				tMsi[sk], err = ConverToMsi(v)
			} else {
				return nil, fmt.Errorf("%v not a string", k)
			}
		}
		return tMsi, nil
	case []interface{}:
		var tsi []interface{}
		for _, v := range rv {
			if t, err := ConverToMsi(v); err == nil {
				tsi = append(tsi, t)
			}
		}
		return tsi, nil

	case map[string]interface{}:
		tMsi := make(map[string]interface{})
		for k, v := range rv {
			tMsi[k], err = ConverToMsi(v)
		}
		return tMsi, nil
	case interface{}:
		dst = src
		return dst, nil
	}

	return nil, nil
}
