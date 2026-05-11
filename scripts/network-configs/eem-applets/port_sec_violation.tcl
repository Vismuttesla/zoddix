! =====================================================================
! EEM applet : PORT_SEC_VIOLATION
! Platform   : Catalyst 3560G (IOS 12.2(50)SE+, EEM 3.x)
! KXD ref.   : P1 (binding/block), P2 (DoS / scan / unauthorized)
! Trigger    : %PORT_SECURITY-2-PSECURE_VIOLATION syslog message
! Outcome    : - Save the offending port's running-config to flash
!              - Emit an SNMP trap with port + MAC for TAA
!              - Emit a critical syslog line that TAA can match on
! NOTE       : Filename ends in .tcl for archival consistency only.
!              The body below is IOS CLI 'event manager applet'
!              syntax (not TCL policy).
! Install    : paste in 'configure terminal' on core-sw01
! Manual run : 'event manager run PORT_SEC_VIOLATION' (uses event none)
! =====================================================================

no event manager applet PORT_SEC_VIOLATION
!
event manager applet PORT_SEC_VIOLATION
 description "TAA - port-security violation responder"
 event tag real syslog pattern "PSECURE_VIOLATION" maxrun 30
 event tag manual none
 trigger
  correlate event real or event manual
 action 0010 cli command "enable"
 action 0020 regexp "(Gi[0-9]+/[0-9]+)" "$_syslog_msg" _match port
 action 0030 if $_regexp_result eq "0"
 action 0035  set port "unknown"
 action 0040 end
 action 0050 regexp "([0-9a-fA-F]{4}\\.[0-9a-fA-F]{4}\\.[0-9a-fA-F]{4})" "$_syslog_msg" _match mac
 action 0060 if $_regexp_result eq "0"
 action 0065  set mac "unknown"
 action 0070 end
 action 0080 cli command "show clock | append flash:/violations.log"
 action 0090 cli command "show running-config interface $port | append flash:/violations.log"
 action 0100 cli command "show mac address-table interface $port | append flash:/violations.log"
 action 0110 snmp-trap strdata "TAA-PSEC port=$port mac=$mac host=core-sw01"
 action 0120 syslog priority critical msg "TAA-ALERT: PSEC violation port=$port mac=$mac"
 action 0130 cli command "end"
!
end
