! =====================================================================
! EEM applet : WAN_BRUTE_DETECT
! Platform   : Cisco 1800 series (IOS 12.4(15)T+, EEM 2.4)
! KXD ref.   : P2 (WAN-side brute force / scan), P4 (alert pipeline)
! Trigger    : 5 'Authentication failure' lines in any 60-second window
! Outcome    : - Capture 'show users' + 'show logging' to flash
!              - Send a generic SNMP trap with the offending event
!              - Send a syslog warning to TAA (10.0.10.10)
!              - Email a short notice via the mail server, if reachable
!                (10.0.10.10 - the TAA host may run a local MTA / smtpd)
! NOTE       : Filename ends in .tcl for archival consistency only.
!              The body below is IOS CLI 'event manager applet' syntax.
! Install    : paste in 'configure terminal' on edge-rt01
! Manual run : 'event manager run WAN_BRUTE_DETECT'
! =====================================================================

no event manager applet WAN_BRUTE_DETECT
!
event manager applet WAN_BRUTE_DETECT
 description "TAA - WAN brute force / repeated auth failure responder"
 event tag real syslog pattern "Authentication failure" period 60 occurs 5
 event tag manual none
 trigger
  correlate event real or event manual
 action 0010 cli command "enable"
 action 0020 cli command "show clock        | append flash:/brute.log"
 action 0030 cli command "show users        | append flash:/brute.log"
 action 0040 cli command "show logging | include Authentication failure | append flash:/brute.log"
 action 0050 snmp-trap strdata "TAA-BRUTE host=edge-rt01 threshold=5/60s"
 action 0060 syslog priority warnings msg "TAA-ALERT: 5+ authentication failures in 60s on edge-rt01"
 action 0070 mail server "10.0.10.10" to "noc@taa.local" from "edge-rt01@taa.local" subject "TAA-ALERT: WAN brute force on edge-rt01" body "edge-rt01 saw 5+ 'Authentication failure' events within 60 seconds. See flash:/brute.log for the latest 'show users' / 'show logging' capture."
!
end
