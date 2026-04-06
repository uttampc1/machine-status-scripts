1) Execute install.sh script. This will install machine-status script in /usr/local/bin directory.
2) Make sure /usr/local/bin is in your $PATH
3) It support following commands,
```sh
   $ machine-status                             -- Show current status
   $ machine-reserve < name | email | phone >   -- Reserve the machine. Arguments are optional.
   $ machine-release                            -- Release from reservation
   $ machine-report                             -- Display simple text report
```

Here is an output from machine-status command.
```console
$ machine-status
======================================================================

>>>> Machine is available <<<<
Since: Sat Apr  4 10:31:46 PM UTC 2026

Usage:
        $ machine-status               -- To check machine status
        $ machine-reserve <Name|email> -- To reserve
        $ machine-release              -- To make it available for others
        $ machine-report               -- Simple text report

IMPORTANT NOTE:
        When done, release the machine using the machine-release command.

Disclaimer:
        This is for coordination and information purposes only.
        DO NOT ASSUME THAT IT WILL PREVENT ACTUAL USE OF THE MACHINE.

======================================================================

```
