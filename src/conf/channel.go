package conf

import (
	"os"
	"path"
	"strings"
)

//"os"

type Channel map[*Architecture]*Target

type Target struct {
	OverWriteConfig Build
	Version         string
	Arch          Architecture
	Description     string
	Files           *Files
}

type Files struct {
	Base        Path
	Aitootfs    []Path
	Packages    []Path
	VersionFile Path
	Arch        Path
	Conf        Path
}

// ディレクトリからチャンネルを読み取ります

func MakeChannel(dir Path) (*Channel, error) {
	ch := Channel{}

	archList, err := GetArchList(dir)
	if err !=nil{
		return nil, err
	}

	for _, a := range archList{
		f, err := GetFilesFromBase(dir, a)
		if err !=nil{
			return nil, err
		}
		t, err := GetTargetFromFiles(f, a)
		if err !=nil{
			return nil, err
		}
		ch[a]=t
	}

	return &ch, nil
}

// ディレクトリからアーキテクチャリストを取得
func GetArchList(dir Path)([]*Architecture, error){
	arch := []*Architecture{}

	bytes, err := os.ReadFile(path.Join(string(dir), "architecture"))
	if err !=nil{
		return nil, err
	}

	for _,archString := range strings.Split(string(bytes), "\n"){
		a, err := GetArchFromString(archString)
		if err !=nil{
			return nil, err
		}
		arch=append(arch, a)
	}

	return arch,nil
}

func GetFilesFromBase(dir Path, arch *Architecture)(*Files, error){
	f := Files{}

	return &f, nil
}

func GetTargetFromFiles(dir *Files, arch *Architecture)(*Target, error){
	return nil, nil
}
