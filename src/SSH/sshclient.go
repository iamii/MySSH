package SSH

import (
	"errors"
	"os"
	"strconv"
	"time"

	"bufio"
	"bytes"
	"fmt"
	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
	"io"
	"strings"

	"github.com/yuin/gopher-lua"
	"layeh.com/gopher-luar"

	. "commondef"
	"crypto/x509"
	"encoding/pem"
	"io/ioutil"
	. "logdebug"
	zx "zabbixx"
)

// MYSSHClient状态
type STATE int

const (
	STATE_INIT  = -2 - iota //初始化
	STATE_CONN              //连接中
	STATE_FAIL              //连接失败
	STATE_ESTAB             //连接确立
	//STATE_CLOSE                     //关闭中
	//STATE_DOWN                      //连接关闭
)

type Message struct {
	Code int
	Msg  interface{}
}

type Eventmsg struct {
	Src  interface{}
	Dst  interface{}
	Info interface{}
}

type Server struct {
	Name    string
	Ip      string
	Port    int
	User    string
	Auth    string
	Passwd  string
	Keyfile string
	Timeout int
	Script  string
	St      string
}

type ResultOfExec struct {
	Cmd    string
	Return int
	Out    string
	Err    string
	Time   time.Duration
}

type MySSHClient struct {
	//Host      Server
	Server
	Ch        chan *Message
	plCh      chan<- *Message
	State     STATE
	sc        *ssh.Client
	Histories map[time.Time]ResultOfExec
}

func parseEncryptedPrivateKey(key []byte, passphrase string) (ssh.Signer, error) {
	block, _ := pem.Decode(key)
	key, err := x509.DecryptPEMBlock(block, []byte(passphrase))
	if err != nil {
		return nil, err
	}
	block.Headers = nil
	block.Bytes = key
	return ssh.ParsePrivateKey(pem.EncodeToMemory(block))
}

func NewMySSHClient(server Server, WAIT_CONN_INIT bool, plch chan *Message) (*MySSHClient, error) {
	var config *ssh.ClientConfig
	if server.Auth == "pw" {
		config = &ssh.ClientConfig{
			User: server.User,
			Auth: []ssh.AuthMethod{
				ssh.Password(server.Passwd),
			},
			Timeout: time.Second * time.Duration(server.Timeout),
		}
		///*
	} else if server.Auth == "pk" {
		key, err := ioutil.ReadFile(server.Keyfile)
		if err != nil {
			ERROR("不能读取私钥文件.", server.Name)
			return nil, fmt.Errorf("不能读取 %s 配置的私钥文件.", server.Name)
		}

		var signer ssh.Signer

		if server.Passwd != "" {
			signer, err = parseEncryptedPrivateKey(key, server.Passwd)
		} else {
			signer, err = ssh.ParsePrivateKey(key)
		}
		if err != nil {
			ERROR("不能解析私钥文件.", server.Keyfile)
			return nil, fmt.Errorf("不能解析配置的私钥文件:%v", server.Keyfile)
		}

		config = &ssh.ClientConfig{
			User: server.User,
			Auth: []ssh.AuthMethod{
				ssh.PublicKeys(signer),
			},
			Timeout: time.Second * time.Duration(server.Timeout),
		}
		//*/

	}

	/////初始化
	ch := make(chan *Message, 1024)
	histories := make(map[time.Time]ResultOfExec)
	//sc == nil
	msc := &MySSHClient{Server: server, Ch: ch, plCh: plch, State: STATE_INIT, Histories: histories}

	go msc.connect("tcp", server.Ip+":"+strconv.Itoa(int(server.Port)), config)

	if WAIT_CONN_INIT {
		t := <-msc.Ch
		switch t.Code {
		case STATE_FAIL:
			return msc, errors.New("Failed to dail : tcp " + server.Ip + ":" + strconv.Itoa(int(server.Port)))
		case STATE_ESTAB:
			DEBUG("Successed to dail : tcp " + server.Ip + ":" + strconv.Itoa(int(server.Port)))
			return msc, nil
		}
	}

	return msc, nil
}

func (msc *MySSHClient) connect(network, addr string, config *ssh.ClientConfig) (*ssh.Client, error) {

	msc.State = STATE_CONN
	sc, err := ssh.Dial(network, addr, config)
	if err != nil {
		msc.State = STATE_FAIL
		//msc.Ch <- &Message{Code:STATE_FAIL, Msg:err}
		return nil, err
	}

	msc.sc = sc
	msc.State = STATE_ESTAB
	//msc.Ch <- &Message{Code:STATE_ESTAB, Msg:"done"}

	return sc, err
}

func (msc *MySSHClient) DisplayHistories() {

	sorted_keys := make([]time.Time, 0)
	for k, _ := range msc.Histories {
		sorted_keys = append(sorted_keys, k)
	}
	l := len(sorted_keys)
	for i := 1; i < l; i++ {
		for j := 0; j < i; j++ {
			if sorted_keys[i].Before(sorted_keys[j]) {
				sorted_keys[i], sorted_keys[j] = sorted_keys[j], sorted_keys[i]
			}
		}
	}

	for _, k := range sorted_keys {
		INFO("开始时间: ", k)
		///*
		INFO("命令/输入: ", msc.Histories[k].Cmd)
		INFO("返回代码: ", msc.Histories[k].Return)
		INFO("标准输出:\n", msc.Histories[k].Out)
		INFO("标准错误: ", msc.Histories[k].Err)
		INFO("花费时长: ", msc.Histories[k].Time)
		//*/
	}
}

func (msc *MySSHClient) Cmd(cmds []string) (rt *Message) {
	ch := make(chan *Message)

	for _, cmd := range cmds {
		go func() {
			rt := msc.ExecCmd(cmd)
			ch <- rt
		}()
		//超时
		select {
		case rt = <-ch:
		case <-time.After(time.Duration(msc.Timeout*300) * time.Second):
			//case <-time.After(time.Duration(msc.Timeout*3)*time.Second):
			ERROR(msc.Name, " exec \" ", cmd, " \" time out.")
			rt = &Message{Code: -1, Msg: errors.New("Cmd exec time out")}
		}
		if _, ok := rt.Msg.(error); ok {
			rt.Code = -1
			return rt
		}
	}

	return
}

func (msc *MySSHClient) ExecCmd(cmd string) *Message {
	DEBUG(msc.Name, "-->SSHclient.ExecCmd:==>", cmd)

	var returnCode int

	session, err := msc.sc.NewSession()
	defer session.Close()
	var stdout, stderr bytes.Buffer

	if err != nil {
		return &Message{Code: -1, Msg: fmt.Errorf("Failed to create session : %v", err.Error())}
	} else {
		stime := time.Now()
		etime := stime

		session.Stdout = &stdout
		session.Stderr = &stderr

		if err := session.Run(cmd); err != nil {
			if exitErr, ok := err.(*ssh.ExitError); ok {
				returnCode = exitErr.ExitStatus()
			} else {
				returnCode = -1
			}

		}
		etime = time.Now()
		//
		result := ResultOfExec{
			Cmd:    cmd,
			Return: returnCode,
			Out:    stdout.String(),
			Err:    stderr.String(),
			Time:   etime.Sub(stime),
		}
		msc.Histories[stime] = result
	}

	msg := stdout.String()

	if stderr.String() != "" {
		msg = stderr.String()
	}

	rt := &Message{Code: returnCode, Msg: msg}

	msc.plCh <- &Message{Code: -3000, Msg: Eventmsg{Src: msc.Name, Info: rt}}

	return rt
}

func (msc *MySSHClient) RunIa(input []string, timeout int) (rt *Message) {
	DEBUG(msc.Name, "-->RunIa:==>", input, timeout)

	session, err := msc.sc.NewSession()
	defer session.Close()

	stdin, err := session.StdinPipe()
	if err != nil {
		return &Message{Code: -1, Msg: errors.New("RunIa get stdinpipe() error")}
	}
	stdout, err := session.StdoutPipe()
	if err != nil {
		return &Message{Code: -1, Msg: errors.New("RunIa get stdoutpipe() error")}
	}
	stderr, err := session.StderrPipe()
	if err != nil {
		return &Message{Code: -1, Msg: errors.New("RunIa get stdoutpipe() error")}
	}

	stime := time.Now()
	etime := stime

	modes := ssh.TerminalModes{
		ssh.ECHO:          0,
		ssh.TTY_OP_ISPEED: 14400,
		ssh.TTY_OP_OSPEED: 14400,
	}
	err = session.RequestPty("xterm", 25, 80, modes)

	if err := session.Shell(); err != nil {
		panic("Failed to Shell:" + err.Error())
	}

	cho := make(chan string)
	che := make(chan string)
	var strout, strerr string

	// get stdout
	go func() {
		//var so string
		bfout := bufio.NewReader(stdout)
		for {
			//_, e := stdout.Read(buf)
			ol, e := bfout.ReadString('\n')
			DEBUG(msc.Name, "-->ia stdout:", ol)
			if e == io.EOF {
				break
			}
			strout += ol
			//bfout.Reset(stdout)
		}
		cho <- strout
		return
	}()

	// get stderr
	go func() {
		bferr := bufio.NewReader(stderr)
		for {
			el, ee := bferr.ReadString('\n')
			DEBUG(msc.Name, "-->ia stderr:", el)
			if ee == io.EOF {
				break
			}
			strerr += el
		}
		che <- strerr
		return
	}()

	// input
	var cmds string
	go func() {
		time.Sleep(time.Second * time.Duration(msc.Timeout))
		for _, v := range input {
			cmds += v
			DEBUG(msc.Name, "ia input:::", v)
			switch v {
			case "\\n":
				stdin.Write([]byte{'\n'})
			case "\\e":
				stdin.Write([]byte{27})
			default:
				stdin.Write([]byte(v))
			}
			time.Sleep(time.Second * time.Duration(msc.Timeout))
		}
		stdin.Write([]byte("exit\n"))
	}()

	select {
	case o := <-cho:
		DEBUG("<====o========", o)
	case e := <-che:
		DEBUG("<====e========\n", e)
	case <-time.After(time.Duration(timeout) * time.Second):
		//signal好像没用，可能没用对
		session.Signal(ssh.SIGKILL)
		return &Message{Code: -1, Msg: errors.New("ia exec time out")}
	}

	etime = time.Now()

	result := ResultOfExec{
		Cmd:    cmds,
		Return: 0,
		Out:    strout,
		Err:    strerr,
		Time:   etime.Sub(stime),
	}

	msc.Histories[stime] = result

	msg := strout

	if strerr != "" {
		msg = strerr
	}

	return &Message{Code: 0, Msg: msg}
}

func (msc *MySSHClient) PutFile(lfile, rfile string) (rt *Message) {
	DEBUG(msc.Name, "->PutFile:::", lfile, " - ", rfile)

	sftpClient, err := sftp.NewClient(msc.sc)
	defer sftpClient.Close()
	if err != nil {
		DEBUG("PutFile Error:", err)
		return &Message{Code: -1, Msg: err}
	}

	srcFile, err := os.Open(lfile)
	defer srcFile.Close()
	if err != nil {
		DEBUG("PutFile Error:", err)
		return &Message{Code: -1, Msg: err}
	}

	dstFile, err := sftpClient.Create(rfile)
	defer dstFile.Close()
	if err != nil {
		DEBUG("PutFile Create Error:", err)
		return &Message{Code: -1, Msg: err}
	}

	if s, err := srcFile.Stat(); err == nil {
		buf := make([]byte, s.Size())
		for {
			n, _ := srcFile.Read(buf)
			if n == 0 {
				break
			}
			dstFile.Write(buf)
		}
	} else {
		DEBUG("PutFile stat Error:", err)
		rt = &Message{Code: -1, Msg: err}
	}

	//DEBUG("===================", rt)
	return
}

func (msc *MySSHClient) GetFile(rfile, lfile string) (rt *Message) {
	sftpClient, errNC := sftp.NewClient(msc.sc)
	defer sftpClient.Close()
	if errNC != nil {
		return &Message{Code: -1, Msg: errNC}
	}

	dstFile, errOP := os.Create(lfile)
	defer dstFile.Close()
	if errOP != nil {
		return &Message{Code: -1, Msg: errOP}
	}

	srcFile, errCT := sftpClient.Open(rfile)
	defer srcFile.Close()
	if errCT != nil {
		return &Message{Code: -1, Msg: errCT}
	}

	if s, err := srcFile.Stat(); err == nil {
		buf := make([]byte, s.Size())

		for {
			n, _ := srcFile.Read(buf)
			if n == 0 {
				break
			}
			dstFile.Write(buf)
		}
	} else {
		DEBUG("Error:", err)
		rt = &Message{Code: -1, Msg: err}
	}
	return
}

func (msc *MySSHClient) Send(message map[string]interface{}) (rt *Message) {
	em := Eventmsg{Src: msc.Name}
	code := 1001
	if hosts, ok := message["dst"].(string); ok {
		em.Dst = strings.Fields(hosts)
	}
	em.Info = message["info"]
	DEBUG("======send msg======", em.Dst, em.Info)

	if em.Info == nil {
		return &Message{Code: -1, Msg: fmt.Errorf("======sendenv error: msg no info======%v", em)}
	}

	if em.Dst == nil { //broadcast
		DEBUG("消息:", em.Info, "的目标为nil，将发送广播")
		code = -1000
		msc.plCh <- &Message{Code: code, Msg: em}
	} else {
		DEBUG("消息:", em.Info, "的目标为:", em.Dst)
		code = -1001
		msc.plCh <- &Message{Code: code, Msg: em}
	}

	rt = &Message{Code: code, Msg: em}

	return
}

func (msc *MySSHClient) Wait(message map[string]interface{}) (rt *Message) {
	wm := Eventmsg{Dst: msc.Name}
	code := -2000
	if src, ok := message["src"]; ok {
		if h, ok := src.(string); ok {
			wm.Src = h
		}
	}

	if info, ok := message["info"]; ok {
		wm.Info = info
	}

	DEBUG(msc.Name, "..开始等待消息...", wm.Src, wm.Info)
	for get := false; get != true; {
		msg := <-msc.Ch
		//DEBUG("----------------------------------------->", reflect.TypeOf(msg.Msg))
		if m, ok := msg.Msg.(Eventmsg); ok {
			if waitSrcHost, ok := wm.Src.(string); ok {
				hosts := strings.Fields(waitSrcHost)
				for i := 0; i < len(hosts); i++ {
					if m.Src != hosts[i] {
						DEBUG("期待的事件消息源主机为：", waitSrcHost, "但收到的消息源为：", m.Src)
						continue
					} else {
						if wm.Info != nil {
							if wm.Info == m.Info {
								DEBUG("等待事件已收到：", m.Info)
								rt = &Message{Code: code, Msg: msg.Msg}
								get = true
								break
							} else {
								DEBUG("指定了等待事件：", wm.Info, "但收到的是：", m.Info)
								continue
							}
						} else {
							//wm.Src = hosts[i]
							DEBUG(msc.Name, "未指定具体等待消息，已收到消息：", m.Info)
							rt = &Message{Code: code, Msg: msg.Msg}
							get = true
							break
						}
					}
				}

			} else if wm.Src == nil && m.Src != msc.Name { //为空，但过滤掉自己发的广播
				DEBUG("..不需要指定消息源和事件...")
				rt = &Message{Code: code, Msg: msg.Msg}
				get = true
				break
			}
		} else {
			DEBUG(msc.Name, "-->未知事件消息：", msg)
			rt = &Message{Code: -1, Msg: fmt.Errorf("未知事件消息：%v", m)}
		}
	}

	return rt
}

func (msc *MySSHClient) ReadFile(fl string) (rt *Message, data string) {
	DEBUG("读取文件:", fl)
	sftpClient, errNC := sftp.NewClient(msc.sc)
	defer sftpClient.Close()
	if errNC != nil {
		return &Message{Code: -1, Msg: errNC}, ""
	}
	srcFile, errCT := sftpClient.Open(fl)
	defer srcFile.Close()
	if errCT != nil {
		return &Message{Code: -1, Msg: errCT}, ""
	}

	if s, err := srcFile.Stat(); err == nil {
		buf := make([]byte, s.Size())

		for {
			n, _ := srcFile.Read(buf)
			if n == 0 {
				break
			}
		}
		data = string(buf)

	} else {
		DEBUG("Error:", err)
		rt = &Message{Code: -1, Msg: err}
	}
	return
}

func (msc *MySSHClient) WriteFile(fl string, data string) *Message {
	DEBUG("写入文件:", fl)
	sftpClient, errNC := sftp.NewClient(msc.sc)
	defer sftpClient.Close()
	if errNC != nil {
		return &Message{Code: -1, Msg: errNC}
	}
	dstFile, err := sftpClient.Create(fl)
	defer dstFile.Close()
	if err != nil {
		DEBUG("XMLWrite Create Error:", err)
		return &Message{Code: -1, Msg: err}
	}
	dstFile.Write([]byte(data))
	return nil
}

func ClientRegister(L *lua.LState, host MySSHClient) {
	L.SetGlobal("HOST", luar.New(L, host))
	Register(L)
	zx.ZABBIXXRegister(L)
}
