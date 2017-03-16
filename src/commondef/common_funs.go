package commondef

import (
	"bytes"
	"fmt"
	"github.com/yuin/gopher-lua"
	"layeh.com/gopher-luar"
	"reflect"
	"time"
)

func TimeOut(fun func(), timeout int) bool {
	done := make(chan struct{})
	go func() {
		defer close(done)
		fun()
	}()
	select {
	case <-done:
		return false
	case <-time.After(time.Duration(timeout) * time.Second):
		return true
	}
}

func luaDebug(shows ...interface{}) {
	DEBUG(reflect.TypeOf(shows), "::lua debug :::", shows)
}

func luaInfo(shows ...interface{}) {
	INFO("lua info :::", shows)
}

func luaGeterr(err error) string {
	fmt.Println(err)
	return err.Error()
}

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

func Register(L *lua.LState) {
	L.SetGlobal("DEBUG", luar.New(L, luaDebug))
	L.SetGlobal("INFO", luar.New(L, luaInfo))
	L.SetGlobal("printerr", luar.New(L, luaGeterr))

	//
	buf := bytes.Buffer{}
	L.SetGlobal("BUFFER", luar.New(L, buf))
	L.SetGlobal("BUFFER", luar.NewType(L, buf))
}
