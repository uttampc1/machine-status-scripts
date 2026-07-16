0) cd /tmp
1) git clone https://github.com/uttampc1/machine-status-scripts.git
2) cd machine-status-script
3) Execute install.sh script (once). This will install machine-status script in /usr/local/bin directory.
4) Make sure /usr/local/bin is in your $PATH
5) It support following commands,
```sh
   $ machine-status                             -- Show current status
   $ machine-reserve < name | email | phone >   -- Reserve the machine. Arguments are optional.
   $ machine-release                            -- Release from reservation
   $ machine-report                             -- Display simple text report
   $ list_machines                              -- Display list of machines from the backend server
   $ show_machine -m machine_name               -- Display detail information about the server machine
   $ add_machine    --help                      -- Display detail information about the server machine
   $ update_machine --help                      -- Update information about the server machine
   $ delete_machine --help                      -- Delete server machine from the backend database
   $ update_machine_status --help               -- Make a remote reservation. See --help for additional info.
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

Repository:
        https://github.com/uttampc1/machine-status-scripts.git
======================================================================
```

```machine-reserve``` command does two (2) things as shown below,
1) Update the status, and
2) Broadcast a message to all connected users using ```wall``` command.

```console
$ machine-reserve foo@gmail.com
Broadcast message from foo@volcano-9af8-os (pts/4) (Tue May 19 11:50:28 2026):

WARNING: Machine is reserved by foo@gmail.com

Broadcast message from foo@volcano-9af8-os (pts/4) (Tue May 19 11:50:28 2026):

INFO: Use machine-status command to see the latest status.

======================================================================

>>>> foo@gmail.com: Machine is now reserved for you!
Since: Tue May 19 11:42:32 AM PDT 2026

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


Repository:
        https://github.com/uttampc1/machine-status-scripts.git
======================================================================

```
