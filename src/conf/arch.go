package conf

type Architecture string

var (
	ArchX86_64 Architecture = "x86_64"
	ArchPen4   Architecture = "pentium4"
	ArchI686   Architecture = "i686"
)


func GetArchFromString(arch string)(*Architecture, error){
	switch arch {
		case "x86_64":
			return &ArchX86_64, nil
		case "pentium4":
			return &ArchPen4, nil
		case "i686":
			return &ArchI686, nil
		default:
			return nil, ErrNoSuchArch
	}
}
