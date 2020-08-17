extern crate clap;
extern crate regex;

use regex::Regex;
use clap::{App, Arg, SubCommand};
use std::fs::File;
use std::io::{BufRead, BufReader};
fn main() {
    let app = App::new("arch-pkgbuild-parser")
        .version("0.1.0")
        .author("kokkiemouse <Twitter -> @kokkiemouse>")
        .about("PKGBUILD PARSER")
        .arg(Arg::with_name("PKGBUILD_FILE")
            .help("PKGBUILD")
            .short("p")
            .long("pkgbuild")
            .takes_value(true)
            .required(true)
        )
        .arg(Arg::with_name("MAKEDEPENDS")
        .help("makedepends")
        .short("m")
        .long("makedepends")
    );
    let matches = app.get_matches();
    let PKGBUILD_PATH;
    if let Some(o) = matches.value_of("PKGBUILD_FILE") {
        PKGBUILD_PATH=o.to_string();
    }else{
        PKGBUILD_PATH=String::new();
    }
    let makedepends_enable:bool=matches.is_present("MAKEDEPENDS");
    let file = File::open(PKGBUILD_PATH).unwrap();
    let reader=BufReader::new(file);
    let mut file_data_cut=String::new();
    let mut depends_searched:bool=false;
    let mut depends_ended:bool = false;
    let lkun1=Regex::new(r">=.*?'").unwrap();
    let lkun1a=Regex::new(r##">=.*?""##).unwrap();
    for (index, line) in reader.lines().enumerate() {
        if(!depends_searched){
            let line = line.unwrap();
            let mut buf_line=line.clone();
            let buf_lkun=line.clone().replace(" ","");
            buf_line=lkun1.replace_all(&buf_line.clone(),"\'").to_string();
            buf_line=lkun1a.replace_all(&buf_line.clone(),"\"").to_string();
            if(!makedepends_enable){
                if buf_lkun.starts_with("depends") {
                    depends_searched=true;
                    let mut buf_copykun=buf_line.clone();
                    buf_copykun=buf_copykun.replace("depends","");

                    let mut head_bufkun:String = String::new();
                    head_bufkun.push_str("depends");
                    head_bufkun.push_str(&buf_copykun);
                    file_data_cut.push_str(&head_bufkun);
                }
            }else{

                if buf_lkun.starts_with("makedepends") {
                    depends_searched=true;
                    let mut buf_copykun=buf_line.clone();
                    buf_copykun=buf_copykun.replace("makedepends","");

                    let mut head_bufkun:String = String::new();
                    head_bufkun.push_str("makedepends");
                    head_bufkun.push_str(&buf_copykun);
                    file_data_cut.push_str(&head_bufkun);
                }
            }
        }else if (!depends_ended){

            let line = line.unwrap();
            let mut buf_line=line.clone();
            buf_line=lkun1.replace_all(&buf_line.clone(),"\'").to_string();
            buf_line=lkun1a.replace_all(&buf_line.clone(),"\"").to_string();
            let buf_lkun=line.clone().replace(" ","");
            if buf_lkun.ends_with(")") {
                depends_ended=true;
            }
            file_data_cut.push_str(&buf_line);
        }
    }
    let mut depends_count:i64;
    let copy_depends_str:String = file_data_cut.clone();


    println!("{}",file_data_cut);


}
