package configs

import (
	. "github.com/donnie4w/dom4g"
)

type XML struct {
}

func (x *XML) LoadByStr(str string) (*Element, error) {
	return LoadByXml(str)
}

func (x *XML) GetNode(el *Element, str string) *Element {
	return el.Node(str)
}
func (x *XML) GetAttr(el *Element, str string) (interface{}, bool) {
	return el.AttrValue(str)
}
