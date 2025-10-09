package archiso

import (
	"os/exec"

	"github.com/FascodeNet/alterlinux/src/pkg/shutils"
)

func MkarchisoPath() (string, error) {
	mkarchisoPath, err := exec.LookPath("mkarchiso")
	if err != nil {
		return "", err
	}
	return mkarchisoPath, nil
}

func IsInjectable() (bool, error) {
	mkarchisoPath, err := MkarchisoPath()
	if err != nil {
		return false, err
	}

	ast, err := shutils.ParseFile(mkarchisoPath)
	if err != nil {
		return false, err
	}

	f := shutils.Func(ast, "_build")
	shutils.PrintCode(f)

	// TODO: implement the actual check

	return true, nil

}
