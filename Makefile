DESTDIR ?= "/"
PREFIX ?= /usr/local/
LIBDIR ?= $(PREFIX)lib
BINDIR ?= $(PREFIX)bin

COMMON_SH := $(LIBDIR)/btrfs-snapshot-common.sh

UNITS := btrfs-snapshot-cleanup@.timer btrfs-snapshot-cleanup@.service btrfs-snapshot@.timer btrfs-snapshot@.service
BINS := btrfs-snapshot btrfs-snapshot-cleanup
SYSTEMD_UNIT_DIR := $(LIBDIR)/systemd/

.PHONY: build
build: $(UNITS) $(BINS)

%.service: %.service.template
	m4 -D PREFIX="$(PREFIX)" "$<" > "$@"

%: %.in
	m4 -D COMMON_SH="$(COMMON_SH)" "$<" > "$@"

.PHONY: install
install: build
	install -Dm755 -t $(DESTDIR)/$(BINDIR) $(BINS)
	install -Dm755 -t $(DESTDIR)/$(LIBDIR) btrfs-snapshot-common.sh
	install -Dm644 -t $(DESTDIR)/$(SYSTEMD_UNIT_DIR)/system/ $(UNITS)
	install -dm755 $(DESTDIR)/$(SYSTEMD_UNIT_DIR)/user/
	ln -f -s -t $(DESTDIR)/$(SYSTEMD_UNIT_DIR)/user/ $(addprefix ../system/,$(UNITS))

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)/$(addprefix $(BINDIR)/,$(BINS)) $(DESTDIR)/$(addprefix $(SYSTEMD_UNIT_DIR)/system/,$(UNITS)) $(DESTDIR)/$(addprefix $(SYSTEMD_UNIT_DIR)/,$(UNITS))

.PHONY: clean
clean:
	rm -f btrfs-snapshot@.service btrfs-snapshot-cleanup@.service $(BINS)
