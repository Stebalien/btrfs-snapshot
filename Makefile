PREFIX ?= /usr/local

UNITS := btrfs-snapshot-cleanup@.timer btrfs-snapshot-cleanup@.service btrfs-snapshot@.timer btrfs-snapshot@.service
BINS := btrfs-snapshot btrfs-snapshot-cleanup

.PHONY: build
build: $(UNITS)

%.service: %.service.template
	m4 -D PREFIX="$(PREFIX)" "$<" > "$@"

.PHONY: install
install: build
	install -Dm755 -t $(PREFIX)/bin/ $(BINS)
	install -Dm644 -t $(PREFIX)/lib/systemd/system/ $(UNITS)
	install -dm755 $(PREFIX)/lib/systemd/user/
	ln -f -s -t $(PREFIX)/lib/systemd/user/ $(addprefix ../system/,$(UNITS))

.PHONY: uninstall
uninstall:
	rm -f $(addprefix $(PREFIX)/bin/,$(BINS)) $(addprefix $(PREFIX)/lib/systemd/system/,$(UNITS)) $(addprefix $(PREFIX)/lib/systemd/user/,$(UNITS))

.PHONY: clean
clean:
	rm -f btrfs-snapshot@.service btrfs-snapshot-cleanup@.service
