/*
** Copyright (C) 2001-2026 TAA Project
** Based on TAA Agent 2 source code.
**
** This program is free software: you can redistribute it and/or modify it under the terms of
** the GNU Affero General Public License as published by the Free Software Foundation, version 3.
**/

// Package version provides TAA agent release version
package version

import (
	"fmt"
	"runtime"
	"strings"
)

const (
	ZABBIX_REVDATE          = "4 June 2025"
	ZABBIX_VERSION_MAJOR    = 7
	ZABBIX_VERSION_MINOR    = 4
	ZABBIX_VERSION_PATCH    = 0
	ZABBIX_VERSION_RC       = "rc2"
	ZABBIX_VERSION_RC_NUM   = "{ZABBIX_RC_NUM}"
	ZABBIX_VERSION_REVISION = "1.0"

	// TAA uchun o'zgartirilgan mualliflik xabari
	copyrightMessage = "Copyright (C) 2026 TAA Project\n" +
		"Based on TAA Agent 2 source code.\n" +
		"License AGPLv3: GNU Affero General Public License version 3 <https://www.gnu.org/licenses/>.\n" +
		"This is free software: you are free to change and redistribute it according to\n" +
		"the license. There is NO WARRANTY, to the extent permitted by law."
)

var (
	titleMessage  string = "{undefined}"
	compileDate   string = "{undefined}"
	compileTime   string = "{undefined}"
	compileOs     string = "{undefined}"
	compileArch   string = "{undefined}"
	compileMode   string
	extraLicenses []string
)

func RevDate() string {
	return ZABBIX_REVDATE
}

func Major() int {
	return ZABBIX_VERSION_MAJOR
}

func Minor() int {
	return ZABBIX_VERSION_MINOR
}

func Patch() int {
	return ZABBIX_VERSION_PATCH
}

func RC() string {
	return ZABBIX_VERSION_RC
}

func LongStr() string {
	var ver string = fmt.Sprintf("%d.%d.%d", Major(), Minor(), Patch())
	if len(RC()) != 0 {
		ver += " " + RC()
	}
	return ver
}

func Long() string {
	var ver string = fmt.Sprintf("%d.%d.%d", Major(), Minor(), Patch())
	if len(RC()) != 0 {
		ver += RC()
	}
	return ver
}
func LongNoRC() string {
	var ver string = fmt.Sprintf("%d.%d.%d", Major(), Minor(), Patch())
	return ver
}

func Short() string {
	return fmt.Sprintf("%d.%d", Major(), Minor())
}

func Revision() string {
	return ZABBIX_VERSION_REVISION
}

func CopyrightMessage() string {
	msg := copyrightMessage

	for _, license := range extraLicenses {
		msg += license
	}

	return msg
}

func CompileDate() string {
	return compileDate
}

func CompileTime() string {
	return compileTime
}

func CompileOs() string {
	return compileOs
}

func CompileArch() string {
	return compileArch
}

func CompileMode() string {
	return compileMode
}

func TitleMessage() string {
	var title string = titleMessage
	if "windows" == compileOs {
		if -1 < strings.Index(compileArch, "64") {
			title += " Win64"
		} else {
			title += " Win32"
		}
	}

	if len(compileMode) != 0 {
		title += fmt.Sprintf(" (%s)", compileMode)
	}

	return title
}

// Display funksiyasi -V komandasi berilganda ekranga chiqariladi.
// (Zabbix) yozuvi (TAA Agent 2) ga o'zgartirildi.
func Display(additionalMessages []string) {
	// (Zabbix) so'zi olib tashlandi, faqat TAA Agent 2 qoldi
	fmt.Printf("%s TAA Agent 2 %s\n", TitleMessage(), Long())

	// Revision qatoridagi Zabbix so'zini ham olib tashlaymiz
	fmt.Printf(
		"Revision %s %s, compilation time: %s %s, built with: %s\n",
		Revision(), RevDate(), CompileDate(), CompileTime(), runtime.Version(),
	)

	for _, msg := range additionalMessages {
		// Agar qo'shimcha xabarlarda Zabbix bo'lsa, ularni almashtiramiz
		fmt.Println(strings.ReplaceAll(msg, "Zabbix", "TAA"))
	}

	fmt.Println()
	fmt.Println(CopyrightMessage())
}

func Init(title string, extra ...string) {
	titleMessage = title
	extraLicenses = append(extraLicenses, extra...)
}

func init() {
	extraLicenses = make([]string, 0)
}
