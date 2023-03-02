package channel

import (
	"github.com/FascodeNet/alterlinux/src/conf"
)

type Channel struct {
	Config      map[*conf.Architecture]*conf.Build
	Version     string
	Arches      []*conf.Architecture
	Description string
	Airootfs    conf.Path
}

// ディレクトリからチャンネルを読み取ります
func MakeChannel(dir conf.Path) (*Channel, error) {
	ch := Channel{}


	return &ch, nil
}

// ディレクトリからアーキテクチャリストを取得
func GetArchList()([]*conf.Architecture){
	return nil
}
