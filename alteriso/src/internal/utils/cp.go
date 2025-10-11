package utils

import (
	"fmt"
	"io"
	"os"
	"path"
	"strings"
)

func CopyFileWithKV(src, dst string, kv map[string]string) error {
	// ソースファイルを開く
	srcFile, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("failed to open source file %s: %w", src, err)
	}
	defer srcFile.Close()

	// ソースファイルの内容を読み取る
	content, err := io.ReadAll(srcFile)
	if err != nil {
		return fmt.Errorf("failed to read source file %s: %w", src, err)
	}

	// キーバリューペアに基づいて置換を実行
	contentStr := string(content)
	for key, value := range kv {
		placeholder := fmt.Sprintf("%%%s%%", key)
		contentStr = strings.ReplaceAll(contentStr, placeholder, value)
	}

	// 宛先ファイルを作成（ディレクトリも作成）
	err = os.MkdirAll(strings.TrimSuffix(dst, "/"+path.Base(dst)), 0755)
	if err != nil {
		return fmt.Errorf("failed to create destination directory: %w", err)
	}

	dstFile, err := os.Create(dst)
	if err != nil {
		return fmt.Errorf("failed to create destination file %s: %w", dst, err)
	}
	defer dstFile.Close()

	// 置換された内容を宛先ファイルに書き込む
	if _, err = dstFile.WriteString(contentStr); err != nil {
		return fmt.Errorf("failed to write to destination file %s: %w", dst, err)
	}

	return nil
}

func CopyDirWithKV(srcDir, dstDir string, kv map[string]string) error {
	// ソースディレクトリの存在確認
	srcInfo, err := os.Stat(srcDir)
	if err != nil {
		return fmt.Errorf("failed to access source directory %s: %w", srcDir, err)
	}
	if !srcInfo.IsDir() {
		return fmt.Errorf("source path %s is not a directory", srcDir)
	}

	// 宛先ディレクトリを作成
	err = os.MkdirAll(dstDir, srcInfo.Mode())
	if err != nil {
		return fmt.Errorf("failed to create destination directory %s: %w", dstDir, err)
	}

	// ソースディレクトリの内容を読み取る
	entries, err := os.ReadDir(srcDir)
	if err != nil {
		return fmt.Errorf("failed to read source directory %s: %w", srcDir, err)
	}

	// 各エントリを処理
	for _, entry := range entries {
		srcPath := path.Join(srcDir, entry.Name())
		dstPath := path.Join(dstDir, entry.Name())

		if entry.IsDir() {
			// サブディレクトリの場合は再帰的にコピー
			err = CopyDirWithKV(srcPath, dstPath, kv)
			if err != nil {
				return fmt.Errorf("failed to copy subdirectory %s: %w", srcPath, err)
			}
		} else {
			// ファイルの場合はCopyFileWithKVを使用
			err = CopyFileWithKV(srcPath, dstPath, kv)
			if err != nil {
				return fmt.Errorf("failed to copy file %s: %w", srcPath, err)
			}

			// 元ファイルの権限を保持
			srcInfo, err := os.Stat(srcPath)
			if err == nil {
				os.Chmod(dstPath, srcInfo.Mode())
			}
		}
	}

	return nil
}
