# Rewrite channel for AlterISO3.
AlterISO3 was added many new functions,and several specifications were changed.

In this document,here are the steps to update the channel for AlterISO2 => AlterISO3.

## notes
In this document,expressing channel name as`<ch_name>`.Please rewrite your own channel-directory.  

## 1. Create version file.
Please create `<ch_name>/alteriso`and write `alteriso=3.0`.
If this file doesn't exist,this channel is recognized as previous channel and wouldn't be build.

## 2. change Japanese-related code
### config.<arch>
Previous`japanese`variable not working.  
〜Currently,specifications are not defined,so add it later〜  

### customize_airootfs_<ch_name>.sh

The argument parsing part is no longer needed. Please delete the relevant part.
Also, function definitions such as remove are no longer required.
See [share/customize_airootfs.sh](https://github.com/FascodeNet/alterlinux/blob/dev/channels/share/airootfs.any/root/customize_airootfs.sh) for available variables and functions.

##### Previous code

```bash
# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel='zen'
theme_name=alter-logo
rebuild=false
japanese=false
username='alter'
os_name="Alter Linux"
install_dir="alter"
usershell="/bin/bash"
debug=true


# Parse arguments
while getopts 'p:bt:k:rxju:o:i:s:da:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel="${OPTARG}" ;;
        r) rebuild=true ;;
        j) japanese=true;;
        u) username="${OPTARG}" ;;
        o) os_name="${OPTARG}" ;;
        i) install_dir="${OPTARG}" ;;
        s) usershell="${OPTARG}" ;;
        d) debug=true ;;
        x) debug=true; set -xv ;;
        a) arch="${OPTARG}"
    esac
done
```


#### Japanize process part
In the past, the `japanese` variable was separated by `true` or `false`for Japanizing.

But in AlterISO3,`japanese`variable was no longer supported. So it won't be processing correctly.

Instead,please separate process if`language`variable is`ja`or not.  

##### 例
```bash
# Previous code
if [[ "${japanese}" = true ]]; then

# code for AlterISO3
if [[ "${language}" = "ja" ]]; then
```

## 3.Change package-list path
Accompanied by i18n,`jp.<arch>`&`non-jp.<arch>`package-lists was discontinued.  
AlterISO treats those package-lists as normal package-lists.
If  you want to add a package for each language like previously, please use below list; `<ch_name>/packages.<arch>/lang/<lang_name>.<arch>`
