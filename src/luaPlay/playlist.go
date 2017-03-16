package luaPlay

import (
	"SSH"
	. "commondef"
	//cm "commondef"
	"errors"
	"github.com/yuin/gopher-lua"
	"layeh.com/gopher-luar"
	"os"
	"reflect"
	"sync"
	"time"
	zx "zabbixx"
)

type PlayList struct {
	servers map[string]*SSH.MySSHClient
	timeout int //允许所有服务器运行脚本的最长时间
	ch      chan *SSH.Message
	wg      sync.WaitGroup

	setvalue interface{} //保存全局信息，不行只有一开始来条广播
}

func (pl *PlayList) Init(sers map[string]SSH.Server, golbalInfo interface{}, timeout int, WAIT_CONN_INIT bool) error {

	servers := make(map[string]*SSH.MySSHClient)
	ch := make(chan *SSH.Message, 1024)

	for server, serdef := range sers {
		//DEBUG(server, ":::", serdef)
		if serdef.Script == "" {
			ERROR(server, " 的script 为空?")
			return nil
		}
		sshClient, err := SSH.NewMySSHClient(serdef, WAIT_CONN_INIT, ch)
		///
		if err != nil {
			ERROR("NewMySSHClient(): ", err.Error())
		} else {
			servers[server] = sshClient
			///
			servers[server].Name = server
		}
	}

	pl.servers = servers
	pl.setvalue = golbalInfo
	pl.ch = ch
	pl.timeout = timeout
	return nil
}

func (pl *PlayList) getLeastCommonWaitTime() (t int) {

	INFO("计算需要等待的最短时间...")

	for host := range pl.servers {
		pTime := pl.servers[host].Timeout
		if pTime > t {
			t = pTime
		}
	}

	return
}

func (pl *PlayList) Start(GO_WITH_ALL_DONE bool) (err error) {
	if len(pl.servers) == 0 {
		ERROR("一个主机都没找到？？？, 请检查SERVERS项定义")
		return errors.New("一个主机都没找到？？？, 请检查SERVERS项定义")
	}
	if GO_WITH_ALL_DONE {
		//根据所有服务器的timeout计算出最小等待时长
		t := pl.getLeastCommonWaitTime()
		INFO("主‘进程’休眠", t, "秒")
		time.Sleep(time.Second * time.Duration(t))
		for hostName := range pl.servers {
			host := pl.servers[hostName]
			//DEBUG("==============>:::", host.State)
			if host.State != SSH.STATE_ESTAB {
				ERROR(hostName + ":" + host.Ip + " 连接失败.")
				return errors.New("不是所有服务器都连接上了.")
			}
		}
		INFO("所有服务器都已连接上.")
	}

	pl.wg = sync.WaitGroup{}

	for hostName := range pl.servers {
		host := pl.servers[hostName]
		pl.wg.Add(1)
		go pl.gogogo(host)

	}

	//消息分发
	go pl.dispatch()

	//超时判断
	if TimeOut(pl.wg.Wait, pl.timeout) {
		ERROR("===========playlist执行超时===========")
	}

	//	for hostName := range pl.servers {
	//		INFO("<=======显示历史记录=========>", hostName)
	//		pl.servers[hostName].DisplayHistories()
	//	}

	return nil
}

func (pl *PlayList) gogogo(host *SSH.MySSHClient) (err error) {
	defer func() {
		if r := recover(); r != nil {
			ERROR("Get panic: ", r)
			os.Exit(-1)
		}
	}()
	//pl.ch <- SSH.Message{Msg:pl.dispatch(host, scripts), Code:0}
	//DEBUG(host, "=============", host.Host.Script)
	L := lua.NewState()
	defer L.Close()

	// 注册一个新playlist，可以在lua脚本中“无限创建playlist"
	sub_pl := PlayList{}
	L.SetGlobal("SubPlay", luar.New(L, sub_pl))
	L.SetGlobal("SubPlay", luar.NewType(L, sub_pl))

	SSH.ClientRegister(L, *host)

	if host.St == "file" {
		err = L.DoFile(host.Script)
	} else if host.St == "string" {
		err = L.DoString(host.Script)
	} else {
		err = errors.New("脚本类型未指定或不是file/string")
	}

	if err != nil {
		panic(err)
	}

	pl.wg.Done()
	return nil
}

func (pl *PlayList) dispatch() {
	var em *SSH.Eventmsg
	if (pl.setvalue != nil){
		em = &SSH.Eventmsg{Src: "playlist", Info: pl.setvalue}
	}
	for h := range pl.servers {
		pl.servers[h].Ch <- &SSH.Message{Code: -1000, Msg: em}
	}

	for {
		msg := <-pl.ch
		if msg == nil {
			continue
		}
		//DEBUG("---dispatch() pl.ch  get---", msg.Code)
		switch msg.Code {
		case -1000: //广播消息
			if m, ok := msg.Msg.(SSH.Eventmsg); ok {
				for h := range pl.servers {
					pl.servers[h].Ch <- &SSH.Message{Code: msg.Code, Msg: m}
				}
				DEBUG(":::::::::pl.ch get 广播消息已发送:::::", msg.Msg)
			} else {
				ERROR("未知消息格式。。。", msg.Msg)
			}

		case -1001: //指定发送
			if m, ok := msg.Msg.(SSH.Eventmsg); ok {
				for _, v := range m.Dst.([]string) {
					if h, ok := pl.servers[v]; ok {
						h.Ch <- &SSH.Message{Code: 1001, Msg: m}
						DEBUG(":::pl.ch get 指定消息已发送:::", msg.Msg)
					}
				}
			} else {
				ERROR("未知消息格式。。。", msg.Msg)
			}
		case -2000:
			DEBUG(":::pl.ch get 事件已收到:::", msg.Msg)
		case -3000: //显示执行结果
			if m, ok := msg.Msg.(SSH.Eventmsg); ok {
				// DEBUG(m.Src, "::: exec return ::Info:", m.Info)
				if r, ok := m.Info.(*SSH.Message); ok {
					if r.Code != 0 {
						WARN(m.Src, " 非0返回: Code:", r.Code, ":::Msg:", r.Msg)
					}
				}
			} else {
				DEBUG(reflect.TypeOf(msg.Msg))
			}
		default:
			DEBUG(":::pl.ch get 其它:::Code:", msg.Code, ":::Msg:", msg.Msg)
		}
	}
}

func (pl *PlayList) GetHistory(hostname string) map[time.Time]SSH.ResultOfExec {
	return pl.servers[hostname].Histories
}

func RegisterPlaylist(L *lua.LState) {
	pl := PlayList{}
	Register(L)
	L.SetGlobal("playlist", luar.New(L, pl))
	L.SetGlobal("playlist", luar.NewType(L, pl))
	zx.ZABBIXXRegister(L)
}
