! =====================================================================
! EEM applet : EXPORT_BINDING_HOURLY
! Platform   : Catalyst 3560G (IOS 12.2(50)SE+, EEM 3.x)
! KXD ref.   : P5 (IP / MAC / port inventory feed to TAA)
! Trigger    : cron-style timer, top of every hour
! Outcome    : - Upload the DHCP snooping binding table to the TAA TFTP
!                server (10.0.10.10)
!              - Upload the running-config so the TAA server keeps
!                rolling config snapshots
! NOTE       : The TFTP server on the TAA host (tftpd-hpa) must allow
!              create + overwrite under /srv/tftp/binding and
!              /srv/tftp/configs.
! Install    : paste in 'configure terminal' on core-sw01
! Manual run : 'event manager run EXPORT_BINDING_HOURLY'
! =====================================================================

no event manager applet EXPORT_BINDING_HOURLY
!
event manager applet EXPORT_BINDING_HOURLY
 description "TAA - hourly export of DHCP snooping bindings + config"
 event tag real timer cron name BINDING cron-entry "0 * * * *"
 event tag manual none
 trigger
  correlate event real or event manual
 action 0010 cli command "enable"
 action 0020 cli command "show clock | append flash:/export.log"
 action 0030 cli command "show ip dhcp snooping binding | redirect tftp://10.0.10.10/binding/core-sw01_binding.txt"
 action 0040 cli command "show mac address-table dynamic | redirect tftp://10.0.10.10/binding/core-sw01_mac.txt"
 action 0050 cli command "show interfaces status | redirect tftp://10.0.10.10/binding/core-sw01_ports.txt"
 action 0060 cli command "copy running-config tftp://10.0.10.10/configs/core-sw01.cfg" pattern "Address|filename"
 action 0070 cli command ""
 action 0080 cli command ""
 action 0090 syslog priority informational msg "TAA-INFO: hourly inventory export sent to 10.0.10.10"
!
end
