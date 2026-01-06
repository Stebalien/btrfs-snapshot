PREFIX ?= /usr/local

UNITS := btrfs-snapshot-cleanup@.timer btrfs-snapshot-cleanup@.service btrfs-snapshot@.timer btrfs-snapshot@.service
BINS := btrfs-snapshot btrfs-snapshot-cleanup
SYSTEMD_UNIT_DIR := $(PREFIX)/lib/systemd/

.PHONY: build
build: $(UNITS)

%.service: %.service.template
	m4 -D PREFIX="$(PREFIX)" "$<" > "$@"

.PHONY: install
install: build
	install -Dm755 -t $(PREFIX)/bin/ $(BINS)
	install -Dm644 -t $(SYSTEMD_UNIT_DIR)/system/ $(UNITS)
	install -dm755 $(SYSTEMD_UNIT_DIR)/user/
	ln -f -s -t $(SYSTEMD_UNIT_DIR)/user/ $(addprefix ../system/,$(UNITS))

.PHONY: uninstall
uninstall:
	rm -f $(addprefix $(PREFIX)/bin/,$(BINS)) $(addprefix $(SYSTEMD_UNIT_DIR)/system/,$(UNITS)) $(addprefix $(SYSTEMD_UNIT_DIR)/,$(UNITS))

.PHONY: clean
clean:
	rm -f btrfs-snapshot@.service btrfs-snapshot-cleanup@.service
