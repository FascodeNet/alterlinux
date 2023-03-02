package conf

import (
	//"os"
)

type BuildTarget struct {
	OverWriteConfig      BuildConf
	Version     string
	Arches      Architecture
	Description string
	Files Files
}

type Files struct{
	Base Path
	Aitootfs []Path
	Packages []Path
	VersionFile Path
	Arch Path
	Conf Path
}

// ディレクトリからチャンネルを読み取ります
/*
func MakeChannel(dir conf.Path, arch conf.Architecture) (*Build, error) {
	ch := Build{}


	return &ch, nil
}

// ディレクトリからアーキテクチャリストを取得
func GetArchList(dir conf.Path)([]*conf.Architecture, error){
	arch := []*conf.Architecture{}

	bytes, err := os.ReadFile(string(dir))

	return arch,nil
}
*/
