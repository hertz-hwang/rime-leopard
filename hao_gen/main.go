package main

import (
	"bytes"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime/pprof"
	"sort"
	"strings"
	"sync"

	"hao_gen/tools"
	"hao_gen/types"
	"hao_gen/utils"
)

type Args struct {
	Quiet      bool   `flag:"q" usage:"安静模式，不输出进度信息" default:"false"`
	Div        string `flag:"d" usage:"拆分表文件"  default:"../table/hao_div.txt"`
	Simp       string `flag:"s" usage:"简码表文件" default:"../table/hao_simp.txt"`
	Map        string `flag:"m" usage:"映射表文件"  default:"../table/hao_map.txt"`
	Freq       string `flag:"f" usage:"频率表文件"  default:"../table/freq.txt"`
	White      string `flag:"w" usage:"白名单文件" default:"../table/cjkext_whitelist.txt"`
	Char       string `flag:"c" usage:"输出CJK码表文件"     default:"/tmp/char.txt"`
	Full       string `flag:"u" usage:"输出全码表文件" default:"/tmp/fullcode.txt"`
	Opencc     string `flag:"o" usage:"输出拆分表文件"  default:"/tmp/div.txt"`
	CPUProfile string `flag:"p" usage:"CPU性能分析文件" default:"/tmp/hao_gen.prof"`
	Debug      bool   `flag:"D" usage:"调试模式" default:"false"`
}

var args Args

func main() {
	err := utils.ParseFlags(&args)
	if err != nil {
		log.Fatalf("解析参数失败: %v", err)
		return
	}

	// CPU性能分析
	if args.CPUProfile != "" {
		f, err := os.Create(args.CPUProfile)
		if err != nil {
			log.Fatalf("无法创建CPU性能分析文件: %v", err)
		}
		defer f.Close()
		if err := pprof.StartCPUProfile(f); err != nil {
			log.Fatalf("无法开始CPU性能分析: %v", err)
		}
		defer pprof.StopCPUProfile()
	}

	// 创建输出目录（如果不存在）
	ensureOutputDir(args.Char)
	ensureOutputDir(args.Full)
	ensureOutputDir(args.Opencc)

	// 记录开始时间
	startTime := utils.Now()

	if !args.Quiet {
		fmt.Println("开始加载表格数据...")
	}

	divTable, err := tools.ReadDivisionTable(args.Div)
	if err != nil {
		log.Fatalf("读取拆分表失败: %v", err)
	}
	if !args.Quiet {
		fmt.Printf("拆分表加载完成，共 %d 项\n", len(divTable))
	}

	simpTable, err := tools.ReadCharSimpTable(args.Simp)
	if err != nil {
		log.Fatalf("读取简码表失败: %v", err)
	}
	if !args.Quiet {
		fmt.Printf("简码表加载完成，共 %d 项\n", len(simpTable))
	}

	compMap, err := tools.ReadCompMap(args.Map)
	if err != nil {
		log.Fatalf("读取映射表失败: %v", err)
	}
	if !args.Quiet {
		fmt.Printf("映射表加载完成，共 %d 项\n", len(compMap))
	}

	freqSet, err := tools.ReadCharFreq(args.Freq)
	if err != nil {
		log.Fatalf("读取频率表失败: %v", err)
	}
	if !args.Quiet {
		fmt.Printf("频率表加载完成，共 %d 项\n", len(freqSet))
	}

	cjkExtWhiteSet, err := tools.ReadCJKExtWhitelist(args.White)
	if err != nil {
		log.Fatalf("读取白名单失败: %v", err)
	}
	if !args.Quiet {
		fmt.Printf("白名单加载完成，共 %d 项\n", len(cjkExtWhiteSet))
	}

	if !args.Quiet {
		fmt.Println("开始构建编码数据...")
	}

	buildStartTime := utils.Now()
	charMetaList := tools.BuildCharMetaList(divTable, simpTable, compMap, freqSet, cjkExtWhiteSet)
	charMetaMap := tools.BuildCharMetaMap(charMetaList)
	codeCharMetaMap := tools.BuildCodeCharMetaMap(charMetaList)
	fullCodeMetaList := tools.BuildFullCodeMetaList(divTable, compMap, freqSet, charMetaMap)
	
	if !args.Quiet {
		fmt.Printf("构建完成，耗时: %v\n", utils.Since(buildStartTime))
		fmt.Printf("charMetaList: %d\n", len(charMetaList))
		fmt.Printf("fullCodeMetaList: %d\n", len(fullCodeMetaList))
		fmt.Printf("charMetaMap: %d\n", len(charMetaMap))
		fmt.Printf("codeCharMetaMap: %d\n", len(codeCharMetaMap))
		fmt.Println("开始写入文件...")
	}

	// 使用并行处理加速文件写入
	var wg sync.WaitGroup
	wg.Add(3)
	errChan := make(chan error, 3)

	// CHAR
	go func() {
		defer wg.Done()
		buffer := bytes.Buffer{}
		for _, charMeta := range charMetaList {
			if len(charMeta.Stem) != 0 {
				buffer.WriteString(fmt.Sprintf("%s\t%s\t%d\t%s\n", charMeta.Char, charMeta.Code, charMeta.Freq, charMeta.Stem))
			} else {
				buffer.WriteString(fmt.Sprintf("%s\t%s\t%d\n", charMeta.Char, charMeta.Code, charMeta.Freq))
			}
		}
		err := os.WriteFile(args.Char, buffer.Bytes(), 0o644)
		if err != nil {
			errChan <- fmt.Errorf("写入CHAR文件错误: %w", err)
		} else if !args.Quiet {
			fmt.Printf("CHAR文件写入完成: %s\n", args.Char)
		}
	}()

	// FULLCHAR
	go func() {
		defer wg.Done()
		buffer := bytes.Buffer{}
		for _, charMeta := range fullCodeMetaList {
			buffer.WriteString(fmt.Sprintf("%s\t%s\n", charMeta.Char, charMeta.Code))
		}
		err := os.WriteFile(args.Full, buffer.Bytes(), 0o644)
		if err != nil {
			errChan <- fmt.Errorf("写入FULLCHAR文件错误: %w", err)
		} else if !args.Quiet {
			fmt.Printf("FULLCHAR文件写入完成: %s\n", args.Full)
		}
	}()

	// DIVISION
	go func() {
		defer wg.Done()
		buffer := bytes.Buffer{}
		// 创建一个副本用于排序，避免并发访问问题
		sortedList := make([]*types.CharMeta, len(fullCodeMetaList))
		copy(sortedList, fullCodeMetaList)
		sort.Slice(sortedList, func(i, j int) bool {
			return sortedList[i].Char < sortedList[j].Char
		})
		for _, charMeta := range sortedList {
			divs := divTable[charMeta.Char]
			if !charMeta.MDiv || len(divs) == 0 {
				continue
			}
			div := strings.Join(divs[0].Divs, "")
			buffer.WriteString(fmt.Sprintf("%s\t(%s,%s,%s,%s)\n", charMeta.Char, div, charMeta.Full, divs[0].Pin, divs[0].Set))
		}
		err := os.WriteFile(args.Opencc, buffer.Bytes(), 0o644)
		if err != nil {
			errChan <- fmt.Errorf("写入DIVISION文件错误: %w", err)
		} else if !args.Quiet {
			fmt.Printf("DIVISION文件写入完成: %s\n", args.Opencc)
		}
	}()

	// 等待所有写入操作完成
	wg.Wait()
	close(errChan)

	// 检查是否有错误
	for err := range errChan {
		log.Fatalln(err)
	}

	// 输出处理时间
	if !args.Quiet {
		fmt.Printf("处理完成，总耗时: %v\n", utils.Since(startTime))
	}
}

// 确保输出目录存在
func ensureOutputDir(path string) {
	dir := filepath.Dir(path)
	if dir != "" && dir != "." {
		if err := os.MkdirAll(dir, 0755); err != nil {
			log.Fatalf("无法创建目录 %s: %v", dir, err)
		}
	}
}
