1) Execute install.sh script. This will install machine-status script in /usr/local/bin directory.
2) Make sure /usr/local/bin is in your $PATH
3) It support following commands,
   $ machine-status                           -- Show current status
   $ machine-reserve < name | email | phone > -- Reserve the machine. Arguments are optional.
   $ machine-release                          -- Release from reservation
   $ machine-report                           -- Display simple text report

