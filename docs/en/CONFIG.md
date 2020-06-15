# About Settings
Various settings exist in the build of alteriso.  
The user can change some of these settings with arguments, but some of them only can be changed by editing the configuration file.  
Also, channel developers may wish to prohibit some values from being changed.  
This section explain the changeable values and the order in which the configuration files are loaded.  

# Syntax
All the configuration file is written in bash scripts. Also, all settings are read by the `source` command.  

# Values can be set
The full list of changeable values are in `default.conf`.  
It is recommended that copy the comments with it when you copy the configuration into a separate file and make changes.  

# List of files to be read
They are read in order from the top. Please replace with architecture and channel name when read the `<architecture>` and `<channel_name>`  
If the same variable is set, it is overwritten each time the configuration file is read.  
  
File path | Remarks
--- | ---
default.conf | All values will be set here (essential)
channels/share/config.any | 
channels/share/config.<architecture> | 
channels/<channel_name>/config.any | 
channels/<channel_name>/config.<architecture> | 
