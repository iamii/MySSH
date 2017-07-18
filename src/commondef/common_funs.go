package commondef

import (
	"bytes"
	"configs"
	. "convert"
	"fmt"
	"github.com/yuin/gopher-lua"
	"layeh.com/gopher-luar"
	. "logdebug"
	"reflect"
	"regexp"
	"strings"
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

func Sleep(second int) {
	time.Sleep(time.Second * time.Duration(second))
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

func LuaDeepCopy(L *lua.LState, src *lua.LTable) (dst *lua.LTable) {
	dst = L.NewTable()
	i := 1

	src.ForEach(func(key, value lua.LValue) {
		if lt, ok := value.(*lua.LTable); ok {
			value = LuaDeepCopy(L, lt)
		}

		switch lk := key.(type) {
		case lua.LString:
			dst.RawSetString(lk.String(), value)
		case lua.LNumber:
			dst.RawSetInt(i, value)
			i = i + 1
		}
	})

	return dst
}

func StrMatch(pattern string, srcstr string) (bool, [][]string) {
	r, err := regexp.Compile(pattern)
	if nil == err {
		ss := r.FindAllStringSubmatch(srcstr, -1)
		if len(ss) > 0 {
			return true, ss
		}
	} else {
		ERROR(pattern, "错误：", err)
	}
	return false, nil
}

func StrSplitSpace(srcstr string) []string {
	return strings.Fields(srcstr)
}

/*TemplConfig
根据模板生成配置文件
*/
func TemplConfig(tpl, vars, out interface{}) (err error) {
	//      DEBUG("====================:::", reflect.TypeOf(vars))
	if vv, ok := vars.(*lua.LTable); ok {
		vars = Lua2goValue(vv)
	}

	var nc *configs.TConfig
	if nc, err = configs.NewTemplConfig(tpl, vars, out, "TemplConfig"); err != nil {
		return
	} else {
		err = nc.GetConfigs()
		if err != nil {
			return
		}
	}
	DEBUG("-->TemplConfig==>", err)
	return
}

func Register(L *lua.LState) {
	//DEBUG INFO PRINTERR
	L.SetGlobal("DEBUG", luar.New(L, luaDebug))
	L.SetGlobal("INFO", luar.New(L, luaInfo))
	L.SetGlobal("PRINTERR", luar.New(L, luaGeterr))
	//sleep
	L.SetGlobal("SLEEP", luar.New(L, Sleep))
	//strmatch
	L.SetGlobal("STRMATCH", luar.New(L, StrMatch))
	//buffer
	buf := bytes.Buffer{}
	L.SetGlobal("BUFFER", luar.New(L, buf))
	L.SetGlobal("BUFFER", luar.NewType(L, buf))
	//templconfig
	L.SetGlobal("TEMPLCONFIG", luar.New(L, TemplConfig))
	//xml
	XML := configs.XML{}
	L.SetGlobal("XML", luar.New(L, XML))
	L.SetGlobal("XML", luar.NewType(L, XML))
}
