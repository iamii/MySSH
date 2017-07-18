package configs

import (
	"bytes"
	"errors"
	"gopkg.in/yaml.v2"
	"io"
	"io/ioutil"
	. "logdebug"
	"os"
	"text/template"
)

var tplFuncs = template.FuncMap{
	"KVOPS": KVOptions,
	"DIRS":  Dirs,
	"VHOST": Dirs,
}

type TConfig struct {
	cType string
	tl    *template.Template
	vars  interface{}
	out   interface{}
}

func NewTemplConfig(templ, vars, out interface{}, cType string) (cf *TConfig, err error) {
	DEBUG("NewConfig:::::::::::::::::::;;;;", templ, " : ", vars, " : ", out)

	cf = &TConfig{}
	cf.cType = cType

	if err := cf.setTempl(templ); err != nil {
		return nil, err
	}

	if err := cf.setVars(vars); err != nil {
		return nil, err
	}

	if err := cf.setOut(out); err != nil {
		return nil, err
	}

	return cf, nil
}

func (cf *TConfig) setTempl(templ interface{}) (err error) {
	//DEBUG("cf.setTempl:::::::::::::::::::::", templ)
	switch v := templ.(type) {
	case string:
		if file, err := os.Stat(v); cf.cType == "config" && err == nil && file.IsDir() == false { //是文件并且不是目录
			cf.cType = file.Name()
			cf.tl, err = template.New(cf.cType).Funcs(tplFuncs).ParseFiles(v)
			if err != nil {
				return err
			}
		} else {
			cf.tl, err = template.New(cf.cType).Funcs(tplFuncs).Parse(v)
			if err != nil {
				return err
			}
		}
	case nil:
		cf.tl = nil
	default:
		return errors.New("UnKnown template.")
	}

	return nil
}

func (cf *TConfig) setVars(vars interface{}) error {
	//DEBUG("setVars :::::::::::::::::::::;;", vars)
	switch v := vars.(type) {
	case string:
		if file, err := os.Stat(v); err == nil && file.IsDir() == false {
			data, err := ioutil.ReadFile(v)
			if err != nil {
				return err
			}

			cf.vars = make(map[string]interface{})

			err = yaml.Unmarshal([]byte(data), cf.vars)
			if err != nil {
				return err
			}
			//DEBUG("get cf.vars :::::::::::::::::;", cf.vars)
		} else {
			return errors.New("config.vars只是一个字符串???，或指定的变量文件路径不对。")
		}
	default:
		cf.vars = v
	}
	return nil
}

func (cf *TConfig) setOut(out interface{}) error {
	//DEBUG("out.type:::", reflect.TypeOf(out))
	switch v := out.(type) {
	case string:
		/*
			if _, err := os.Stat(v); err == nil {
				cf.out = v
			}else {
				return errors.New("Out is string, but not a filename.")
			}
		*/
		cf.out = v
	case *bytes.Buffer:
		cf.out = v
	default:
		cf.out = os.Stdout
	}
	//cf.out = out
	return nil
}

func (cf *TConfig) GetConfigs() (err error) {
	//DEBUG("cf.GetConfigs::::::::::::;;", cf.tl, " : ", cf.vars, " : ", cf.out)
	switch v := cf.out.(type) {
	case string:
		//err := cf.tl.Execute(&buf, cf.vars)
		if cf.tl != nil {
			var buf bytes.Buffer
			err = cf.tl.ExecuteTemplate(&buf, cf.cType, cf.vars)
			if err != nil {
				return err
			}
			err = ioutil.WriteFile(v, buf.Bytes(), os.FileMode(0660))
		} else {
			//如果cf.tl为空，默许为yaml输出
			b, err := yaml.Marshal(cf.vars)
			if err != nil {
				return err
			} else {
				err = ioutil.WriteFile(v, b, os.FileMode(0660))
			}

		}

		if err != nil {
			return err
		}

	case io.Writer:
		if cf.tl != nil {
			var buf bytes.Buffer
			err := cf.tl.Execute(&buf, cf.vars)
			if err != nil {
				return err
			}
			if string(buf.Bytes()) == "<no value>" {
				return errors.New("定义未找到.")
			}
			v.Write(buf.Bytes())
		} else {
			b, err := yaml.Marshal(cf.vars)
			if err != nil {
				return err
			} else {
				v.Write(b)
			}
		}

	default:
		return errors.New("Unknown cf.out")
	}

	return nil
}

func (cf *TConfig) table2yaml() error {

	return nil
}
