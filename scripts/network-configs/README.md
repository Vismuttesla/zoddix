# `scripts/network-configs/` - Cisco baseline va EEM applet fayllari

Ushbu papkada TAA loyihasi uchun **Cisco IOS** qurilmalariga yuklanishi kerak
bo'lgan baseline konfiguratsiya fayllari va EEM (Embedded Event Manager)
appletlari saqlanadi. Hujjat `KXD_TAA_SCRIPT_YECHIM.md` da tasvirlangan
yechimning *qurilma tomondagi* qismidir.

> Diqqat: bu papkadagi fayllar **template** hisoblanadi. Ulardagi har bir
> `<REPLACE_ME_*>` placeholder qurilmaga yuklashdan oldin **albatta**
> haqiqiy parol/kalit bilan almashtirilishi shart.

---

## 1. Papka tarkibi

| Fayl | Qurilma | Maqsadi |
|------|---------|---------|
| `catalyst-3560g.cfg` | Catalyst 3560G 48-port (`core-sw01`) | To'liq baseline: VLAN, SVI, port-security, DHCP snooping, ARP inspection, RSTP, SSH, AAA, SNMPv3, logging, NTP |
| `cisco-1800.cfg` | Cisco 1800 router (`edge-rt01`) | Edge/WAN baseline: NAT, WAN/LAN ACL, dot1q sub-interfeyslar, SSH, AAA, SNMPv3, logging, NTP master |
| `eem-applets/port_sec_violation.tcl` | 3560G | `PSECURE_VIOLATION` syslogini ushlab, port + MAC bo'yicha SNMP trap va kritik syslog yuboradi (P1, P2) |
| `eem-applets/stp_loop_detect.tcl` | 3560G | BPDU guard / loopback / loopguard hodisalarini ushlab portni `shutdown` qiladi va emergency trap yuboradi (P3) |
| `eem-applets/export_binding_hourly.tcl` | 3560G | Har soat boshida DHCP snooping binding jadvali va running-config ni TFTP orqali TAA serverga uzatadi (P5) |
| `eem-applets/wan_brute_detect.tcl` | 1800 | 60 sekund ichida 5+ `Authentication failure` log paydo bo'lsa SNMP trap + syslog + email yuboradi (P2, P4) |

> `.tcl` kengaytmasi shartli - fayllar ichida **TCL skripti emas**, balki
> Cisco IOS `event manager applet ... action NNNN cli command "..."`
> sintaksisi joylashgan. Bu shaklda yozish KXD yechim hujjatidagi
> namunalar bilan **bir xil**, va shu bilan birga `event manager
> applet` IOS 12.2(50)SE va 12.4(15)T versiyalarida ishlaydi.

---

## 2. Fayllarni qurilmaga yuklash

### 2.1. TFTP orqali (eng oddiy yo'l)

TAA serverda (`10.0.10.10`) `tftpd-hpa` o'rnatilgan va `/srv/tftp/configs/`
papkasi yozish uchun ochiq bo'lsin.

```bash
# TAA serverdan (DL-160) fayllarni TFTP root ga ko'chirish
sudo cp scripts/network-configs/catalyst-3560g.cfg /srv/tftp/configs/
sudo cp scripts/network-configs/cisco-1800.cfg     /srv/tftp/configs/
sudo chown tftp:tftp /srv/tftp/configs/*.cfg
```

Catalyst 3560G da:

```cisco
core-sw01# copy tftp://10.0.10.10/configs/catalyst-3560g.cfg running-config
core-sw01# copy running-config startup-config
```

Cisco 1800 da:

```cisco
edge-rt01# copy tftp://10.0.10.10/configs/cisco-1800.cfg running-config
edge-rt01# copy running-config startup-config
```

> Maslahat: `running-config` o'rniga to'g'ridan-to'g'ri `startup-config`
> ga yuklash *qurilmani yangidan ko'targanda* tushadi - sessiya
> uzilishidan qo'rqmaslik uchun shu yo'l xavfsizroq:
>
> ```cisco
> copy tftp://10.0.10.10/configs/catalyst-3560g.cfg startup-config
> reload
> ```

### 2.2. SCP orqali (SSH yoqilgandan keyin)

SCP server qurilmada yoqilgan bo'lsa:

```cisco
core-sw01(config)# ip scp server enable
```

TAA serverdan:

```bash
scp scripts/network-configs/catalyst-3560g.cfg \
    taa_auto@10.0.99.2:flash:/catalyst-3560g.cfg

# Keyin qurilma ustida:
core-sw01# copy flash:/catalyst-3560g.cfg running-config
core-sw01# write memory
```

### 2.3. Console / SSH orqali paste

Birinchi marta yuklayotganda (qurilma toza, IP yo'q) yagona yo'l -
**konsol kabeli orqali** baseline ni paste qilish:

```cisco
core-sw01# configure terminal
core-sw01(config)# ! ... fayl mazmunini bu yerga yopishtiring ...
core-sw01(config)# end
core-sw01# write memory
```

---

## 3. EEM applet'larni o'rnatish

EEM applet fayllari **CLI** sintaksisida yozilgan, shuning uchun ularni
shunchaki `configure terminal` rejimiga paste qilish kifoya.

```cisco
core-sw01# configure terminal
core-sw01(config)# ! port_sec_violation.tcl mazmunini bu yerga paste qiling
core-sw01(config)# end
core-sw01# write memory
```

Tartib (3560G uchun):

1. `eem-applets/port_sec_violation.tcl`
2. `eem-applets/stp_loop_detect.tcl`
3. `eem-applets/export_binding_hourly.tcl`

Tartib (1800 uchun):

1. `eem-applets/wan_brute_detect.tcl`

Yuklab bo'lgach tekshirish:

```cisco
core-sw01# show event manager policy registered
core-sw01# show event manager statistics policy
```

---

## 4. Qo'lda (manual) ishga tushirib test qilish

Har bir applet ichida `event tag manual none` qo'shimcha trigger
mavjud. Bu bizga real hodisani kutmasdan applet'ni qo'lda ishga
tushirish imkonini beradi:

```cisco
core-sw01# event manager run PORT_SEC_VIOLATION
core-sw01# event manager run STP_LOOP_DETECT
core-sw01# event manager run EXPORT_BINDING_HOURLY

edge-rt01# event manager run WAN_BRUTE_DETECT
```

So'ngra natijalarni tekshiring:

```cisco
core-sw01# show logging | include TAA-
core-sw01# more flash:/violations.log
core-sw01# more flash:/stp_event.log
core-sw01# more flash:/export.log

edge-rt01# more flash:/brute.log
```

TAA serverda esa SNMP trap'lar `snmptrapd` log fayliga (yoki Zabbix
trapper itemiga) tushishi kerak:

```bash
sudo tail -f /var/log/snmptrapd.log
sudo tail -f /var/lib/zabbix/snmptraps/snmptraps.log
```

---

## 5. Placeholder sekretlarni almashtirish

Quyidagi placeholder'lar fayllarda uchraydi va **albatta** almashtirilishi
shart. Maslahat - sekretlarni alohida `secrets/` papkasida (git'ga
qo'shilmagan) saqlab, deploy paytida `sed` bilan to'ldirish.

| Placeholder | Qaerda | Nima bilan almashtirish |
|-------------|--------|-------------------------|
| `<REPLACE_ME_ENABLE_SECRET>` | `catalyst-3560g.cfg`, `cisco-1800.cfg` | `enable secret` qiymati (kuchli parol) |
| `<REPLACE_ME_USER_PASS>` | `catalyst-3560g.cfg`, `cisco-1800.cfg` | `taa_auto` foydalanuvchining paroli (TAA server `.env` da ham yangilang) |
| `<REPLACE_ME_AUTH_PASS>` | har ikkala `.cfg` | SNMPv3 `auth sha` paroli (≥ 8 belgi) |
| `<REPLACE_ME_PRIV_PASS>` | har ikkala `.cfg` | SNMPv3 `priv aes 128` paroli (≥ 8 belgi) |

Misol (Linux):

```bash
sed -e "s|<REPLACE_ME_ENABLE_SECRET>|S0meStr0ng#En4ble|" \
    -e "s|<REPLACE_ME_USER_PASS>|S0meStr0ng#User|"      \
    -e "s|<REPLACE_ME_AUTH_PASS>|S0meStr0ng#Auth|"      \
    -e "s|<REPLACE_ME_PRIV_PASS>|S0meStr0ng#Priv|"      \
    scripts/network-configs/catalyst-3560g.cfg          \
    > /tmp/catalyst-3560g.cfg.deploy
```

So'ng `/tmp/catalyst-3560g.cfg.deploy` ni TFTP serverga ko'chiring va
qurilmaga yuklang. Faylni qurilmaga yuklab bo'lgach `/tmp/...deploy`
nusxasini **darhol o'chiring**.

---

## 6. KXD muammolari bilan moslashtirish

| KXD muammo | Yechim ushbu papkada qaerda |
|------------|------------------------------|
| **P1** binding/blok | `catalyst-3560g.cfg` - port-security + DHCP snooping + ARP inspection, plus `eem-applets/port_sec_violation.tcl` |
| **P2** ichki tarmoqda DoS/scan | `eem-applets/port_sec_violation.tcl` + storm-control (3560G da har bir port konfiguratsiyasida) |
| **P2** WAN brute | `cisco-1800.cfg` (WAN_IN ACL) + `eem-applets/wan_brute_detect.tcl` |
| **P3** loop | `catalyst-3560g.cfg` - RSTP + loopguard default + bpduguard default, plus `eem-applets/stp_loop_detect.tcl` |
| **P4** alert pipeline | har ikkala `.cfg` da `snmp-server host 10.0.10.10` + `logging host 10.0.10.10`; applet'lar `snmp-trap strdata` chiqaradi |
| **P5** IP jurnal | `eem-applets/export_binding_hourly.tcl` har soatda TFTP push, TAA serverda `ip_inventory.py` qabul qiladi |

---

## 7. Bog'liq hujjatlar

- `D:\TAA\zoddix\KXD_TAA_SCRIPT_YECHIM.md` - umumiy yechim xaritasi
- `scripts/alertscripts/` - TAA tomondagi alert skriptlar (Telegram, auto-remediation)
- `scripts/externalscripts/` - TAA tomondagi parser skriptlar
- `scripts/provisioning/` - port-security va MAC binding'ni 47 portga
  avtomatik tarqatuvchi Ansible/netmiko skriptlar
