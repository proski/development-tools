INSTALL = install
BIN_DIR = /usr/bin
DESKTOP_DIR = /usr/share/applications

install: install-script install-desktop

install-script:
	${INSTALL} -m 755 pdfdispatch ${BIN_DIR}

install-desktop:
	${INSTALL} -m 644 pdfdispatch.desktop ${DESKTOP_DIR}
