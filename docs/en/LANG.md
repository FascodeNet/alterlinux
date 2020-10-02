# About multilingualize
Until before AlterISO 2 can chose only Global edition or japanese edition. but now, AlterISO 3, correspond various language.  
This document will show about that specification, and how to add new language.  

# How to read this
Please replace `<arch>` with build archtecture, `<locale>` with language name, `<ch_name>` with channnel name and read.  

# About language list
Language list is a file that wrote settings can use language when build.  
`system/locale-<arch>` is recognized language list.  
Please wrote language list with follow the under rule.  

```
# <locale name> <locale.gen> <archlinux mirror> <lang version name> <timezone> <fullname>

# Global version
gl      en_US.UTF-8      all    gl     UTC         global

# Japanese
ja      ja_JP.UTF-8      JP     ja     Asia/Tokyo  japanese

# English
en      en_US.UTF-8      US     en     UTC         english
```

## Basic syntax and comment
Line start with `#` treat as comment. Data is separated by a space, and the data is determined from the left.  

## locale name
`locale_name` is used for list of package for language and select when build. Basically, there is no limit, but shorter name recommended.  
Script does not consider duplicate language name, so do not duplicate.  

## locale.gen
This description will comment out in `/etc/locale.gen`. Please do not description text encoding(` UTF-8`, the part of `ja_JP.UTF-8 UTF-8`).  
  
## archlinux mirror
This is string after `/?country=` in this URL, [Mirrorlist Generator](https://www.archlinux.org/mirrorlist/).  
Attention the string of difference ArchLinux32 and ArchLinux.  

## lang version name
This is a language name used for file name of image file. Basically, you should use the same name as `locale name`.

## timezone
This is timezone setting for live enviroment. Please description a path in `/usr/share/zoneinfo` to this.  

## fullname
Fullname of language. This is used for message of build.  
