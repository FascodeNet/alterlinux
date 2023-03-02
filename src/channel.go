package main

type Channel struct {
	Config      map[*Architecture]*Config
	Version     string
	Arches      []*Architecture
	Description string
	Airootfs    Path
}

// ディレクトリからチャンネルを読み取ります
func MakeChannel(dir Path) (*Channel, error) {
	return nil, nil
}
