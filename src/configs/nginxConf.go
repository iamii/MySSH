package configs

import (
//. "commondef"
)

const (
	parse_file = -1 - iota
	parse_block
	parse_param
)

const (
	NGX_CONF_NOARGS = 1 << iota
	NGX_CONF_TAKE1
	NGX_CONF_TAKE2
	NGX_CONF_TAKE3
	NGX_CONF_TAKE4
	NGX_CONF_TAKE5
	NGX_CONF_TAKE6
	NGX_CONF_TAKE7
)

type cf struct {
}

type ngx_str_t struct {
	string
}

type ngx_conf_t struct {
}

type ngx_uint_t struct {
}

type char byte

/*
typedef struct ngx_command_s     ngx_command_t;
struct ngx_command_s {
ngx_str_t             name;
ngx_uint_t            type;
char               *(*set)(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);
ngx_uint_t            conf;
ngx_uint_t            offset;
void                 *post;
};
*/
type ngx_command_s struct {
	Name   ngx_str_t
	Type   ngx_uint_t
	set    func(cf *ngx_conf_t, cmd *ngx_command_t, conf interface{}) (c *char)
	conf   ngx_uint_t
	offset ngx_uint_t
	post   interface{}
}

type ngx_command_t ngx_command_s

func ngx_conf_set_flag_slot(cf *ngx_conf_t, cmd *ngx_command_t, conf interface{}) (c *char) {

	return
}

//char * ngx_conf_parse(ngx_conf_t *cf, ngx_str_t *filename);

func ngx_conf_parse(cf *ngx_conf_t, filename *ngx_str_t) (c *char) {

	return
}

func ngx_conf_read_token() {

}
