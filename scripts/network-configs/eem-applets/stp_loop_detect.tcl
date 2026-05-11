! =====================================================================
! EEM applet : STP_LOOP_DETECT
! Platform   : Catalyst 3560G (IOS 12.2(50)SE+, EEM 3.x)
! KXD ref.   : P3 (loop detection + automatic isolation)
! Trigger    : SPANTREE BPDUGUARD / LOOPBACK / BLOCK_PVID / LOOPGUARD
! Outcome    : - Capture STP state to flash
!              - Shut the offending port
!              - Emit SNMP trap + emergency syslog for TAA
! NOTE       : Filename ends in .tcl for archival consistency only.
!              The body below is IOS CLI 'event manager applet' syntax.
! Install    : paste in 'configure terminal' on core-sw01
! Manual run : 'event manager run STP_LOOP_DETECT'
! =====================================================================

no event manager applet STP_LOOP_DETECT
!
event manager applet STP_LOOP_DETECT
 description "TAA - STP loop / BPDU guard responder"
 event tag real syslog pattern "(SPANTREE.*BPDUGUARD|LOOPBACK|BLOCK_PVID|LOOPGUARD)" maxrun 30
 event tag manual none
 trigger
  correlate event real or event manual
 action 0010 cli command "enable"
 action 0020 regexp "(Gi[0-9]+/[0-9]+)" "$_syslog_msg" _match port
 action 0030 if $_regexp_result eq "0"
 action 0035  set port "unknown"
 action 0040 end
 action 0050 cli command "show clock | append flash:/stp_event.log"
 action 0060 cli command "show spanning-tree active | append flash:/stp_event.log"
 action 0070 cli command "show spanning-tree inconsistentports | append flash:/stp_event.log"
 action 0080 if $port ne "unknown"
 action 0090  cli command "configure terminal"
 action 0100  cli command "interface $port"
 action 0110  cli command "description AUTO-SHUTDOWN STP_LOOP_DETECT"
 action 0120  cli command "shutdown"
 action 0130  cli command "end"
 action 0140 end
 action 0150 snmp-trap strdata "TAA-LOOP port=$port action=shutdown host=core-sw01"
 action 0160 syslog priority emergencies msg "TAA-ALERT: LOOP detected, port=$port shutdown"
!
end
