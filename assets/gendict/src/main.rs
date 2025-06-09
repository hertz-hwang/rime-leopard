use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{self, BufRead, BufReader, Write};
use anyhow::{Result, Context};

// 存储单字编码的结构
#[derive(Debug)]
struct CharCode {
    char: char,
    code: String,
}

// 添加新的结构来存储词条信息
#[derive(Debug)]
struct WordEntry {
    word: String,
    weight: Option<String>,
}

fn main() -> Result<()> {
    // 读取单字码表
    let char_codes = load_char_codes("data/单字全码表.txt")?;
    
    // 创建字符到编码的映射
    let char_to_code: HashMap<char, String> = char_codes
        .into_iter()
        .map(|cc| (cc.char, cc.code))
        .collect();

    let input_file = File::open("../../deploy/hao/多字词.txt")
        .context("无法打开词语文件")?;
    let reader = BufReader::new(input_file);
    
    let mut output = File::create("data/output.txt")
        .context("无法创建输出文件")?;
    let mut error_output = File::create("data/errors.txt")
        .context("无法创建错误日志文件")?;

    for line in reader.lines() {
        let line = line?.trim().to_string();
        if line.is_empty() {
            continue;
        }

        match parse_word_entry(&line) {
            Ok(entry) => {
                let chars: Vec<char> = entry.word.chars().collect();
                match generate_code(&chars, &char_to_code) {
                    Ok(code) => {
                        // 根据是否有权重值来决定输出格式
                        match entry.weight {
                            Some(weight) => writeln!(output, "{}\t{}\t{}", entry.word, code, weight)?,
                            None => writeln!(output, "{}\t{}", entry.word, code)?,
                        }
                    }
                    Err(e) => {
                        writeln!(error_output, "{}\t{}", entry.word, e)?;
                    }
                }
            }
            Err(e) => {
                writeln!(error_output, "解析错误: {}\t{}", line, e)?;
            }
        }
    }

    Ok(())
}

fn load_char_codes(path: &str) -> Result<Vec<CharCode>> {
    let content = fs::read_to_string(path)
        .context("无法读取单字码表文件")?;
    
    let mut char_codes = Vec::new();
    for line in content.lines() {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.is_empty() {
            continue;
        }
        
        // 确保至少有字符和编码两列
        if parts.len() >= 2 {
            let char = parts[0].chars().next()
                .context("无效的字符")?;
            char_codes.push(CharCode {
                char,
                code: parts[1].to_string(),
            });
        }
    }
    Ok(char_codes)
}

fn parse_word_entry(line: &str) -> Result<WordEntry> {
    let parts: Vec<&str> = line.split_whitespace().collect();
    if parts.is_empty() {
        return Err(anyhow::anyhow!("空行"));
    }

    Ok(WordEntry {
        word: parts[0].to_string(),
        weight: parts.get(1).map(|s| s.to_string()),
    })
}

fn generate_two_char_code(
    chars: &[char],
    char_to_code: &HashMap<char, String>
) -> Result<String> {
    let first_code = get_char_code(chars[0], char_to_code)?;
    let second_code = get_char_code(chars[1], char_to_code)?;
    
    // 安全获取编码的前缀，如果长度不足则使用整个字符串并补充所需字符
    let first_prefix = get_safe_prefix(&first_code, 2, 'a');
    let second_prefix = get_safe_prefix(&second_code, 2, 'a');
    
    Ok(format!("{}{}", first_prefix, second_prefix))
}

fn generate_three_char_code(
    chars: &[char],
    char_to_code: &HashMap<char, String>
) -> Result<String> {
    let first_code = get_char_code(chars[0], char_to_code)?;
    let second_code = get_char_code(chars[1], char_to_code)?;
    let third_code = get_char_code(chars[2], char_to_code)?;
    
    // 安全获取编码的前缀
    let first_prefix = get_safe_prefix(&first_code, 1, 'a');
    let second_prefix = get_safe_prefix(&second_code, 1, 'a');
    let third_prefix = get_safe_prefix(&third_code, 2, 'a');
    
    Ok(format!("{}{}{}", first_prefix, second_prefix, third_prefix))
}

fn generate_four_plus_char_code(
    chars: &[char],
    char_to_code: &HashMap<char, String>
) -> Result<String> {
    let first_code = get_char_code(chars[0], char_to_code)?;
    let second_code = get_char_code(chars[1], char_to_code)?;
    let third_code = get_char_code(chars[2], char_to_code)?;
    let last_code = get_char_code(chars[chars.len()-1], char_to_code)?;
    
    // 安全获取编码的前缀
    let first_prefix = get_safe_prefix(&first_code, 1, 'a');
    let second_prefix = get_safe_prefix(&second_code, 1, 'a');
    let third_prefix = get_safe_prefix(&third_code, 1, 'a');
    let last_prefix = get_safe_prefix(&last_code, 1, 'a');
    
    Ok(format!("{}{}{}{}", first_prefix, second_prefix, third_prefix, last_prefix))
}

// 安全获取字符串前缀，如果长度不足则补充字符
fn get_safe_prefix(s: &str, len: usize, fill_char: char) -> String {
    let s_len = s.chars().count();
    if s_len >= len {
        // 如果字符串长度足够，返回前len个字符
        return s.chars().take(len).collect();
    } else {
        // 如果字符串长度不足，返回整个字符串并补充到len长度
        let mut result = s.to_string();
        for _ in 0..(len - s_len) {
            result.push(fill_char);
        }
        return result;
    }
}

fn get_char_code(c: char, char_to_code: &HashMap<char, String>) -> Result<String> {
    char_to_code
        .get(&c)
        .cloned()
        .context(format!("找不到字符'{}'的编码", c))
}

fn generate_code(chars: &[char], char_to_code: &HashMap<char, String>) -> Result<String> {
    match chars.len() {
        2 => generate_two_char_code(chars, char_to_code),
        3 => generate_three_char_code(chars, char_to_code),
        4.. => generate_four_plus_char_code(chars, char_to_code),
        _ => Err(anyhow::anyhow!("词语长度小于2")),
    }
} 