package zabbixx

import (
	. "commondef"
	co "commondef"
	"github.com/AlekSi/zabbix"
	"github.com/layeh/gopher-luar"
	"github.com/pkg/errors"
	"github.com/yuin/gopher-lua"
	"reflect"
)

type API struct {
	zabbix.API
}

func (api *API) Init(url string, user, passwd string) error {
	api.API = *zabbix.NewAPI(url)
	auth, err := api.Login(user, passwd)
	if err != nil {
		DEBUG(":::", err)
		return err
	}
	api.Auth = auth
	return nil
}

func (api *API) CallWithError(method string, params interface{}) (res zabbix.Response, err error) {
	if ttb, err := convert(params); err == nil {
		if ttb, ok := ttb.(map[string]interface{}); ok {
			res, err = api.API.CallWithError(method, ttb)
		}
	} else {
		err = errors.New("params转换失败.")
	}
	DEBUG(res, ":::", err)
	return
}

func (api *API) HostGroupsGet(params interface{}) (res zabbix.HostGroups, err error) {
	if ttb, err := convert(params); err == nil {
		if ttb, ok := ttb.(map[string]interface{}); ok {
			res, err = api.API.HostGroupsGet(ttb)
		}
	} else {
		err = errors.New("params转换失败.")
	}
	//DEBUG(res,":::", err)
	return
}

func convert(params interface{}) (ret interface{}, err error) {
	DEBUG(reflect.TypeOf(params), "::::::::::::::::", params)
	if ltb, ok := params.(*lua.LTable); ok {
		ret = co.Lua2goValue(ltb)
	}

	DEBUG(reflect.TypeOf(ret), "::::::::::::::::", ret)
	ret, err = co.ConverToMsi(ret)
	DEBUG(reflect.TypeOf(ret), ":::", ret, "-------------", err)
	return
}

func ZABBIXXRegister(L *lua.LState) {
	api := API{}
	L.SetGlobal("zabbixx", luar.New(L, api))
	L.SetGlobal("zabbixx", luar.NewType(L, api))
}