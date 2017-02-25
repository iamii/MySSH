package main

import (
	"flag"

	"github.com/yuin/gopher-lua"

	. "commondef"
	"luaPlay"
)

func main() {
	defer InitNewLogFile("test.log").Close()
	WARN("此工具仅供搞笑，请勿用于生产环境；使用后果自负。")

	SetLogLevel(LevelInfo)
	///*
	defer func() {
		if r := recover(); r != nil {
			ERROR("Get panic: ", r)
		}
	}()
	//*/

	luafile := flag.String("l", "../books/main.lua", "TO play lua")
	debug := flag.Bool("d", false, "Show debug info")

	flag.Parse()

	if *debug {
		SetLogLevel(LevelDebug)
	}

	if *luafile != "" {
		// lua.RegistrySize = 1024 * 20
		// lua.CallStackSize = 1024
		L := lua.NewState()
		defer L.Close()
		luaPlay.RegisterPlaylist(L)
		if err := L.DoFile(*luafile); err != nil {
			panic(err)
		}
	}
}
