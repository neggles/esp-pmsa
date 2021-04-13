.PHONY: all clean web

BOARDS = esp-pmsa esp-pmsa-panel
GITREPO = https://github.com/neg2led/esp-pmsa.git
JLCFAB_IGNORE = H1,H2,H3,H4,J1,J2,JP1,PS1,I2C1,JP2,D3,J3,NT1,LOGO1

BOARDSFILES = $(addprefix build/, $(BOARDS:=.kicad_pcb))
SCHFILES = $(addprefix build/, $(BOARDS:=.sch))
GERBERS = $(addprefix build/, $(BOARDS:=-gerber.zip))
JLCGERBERS = $(addprefix build/, $(BOARDS:=-jlcpcb.zip))

RADIUS=1

all: $(GERBERS) $(JLCGERBERS) build/web/index.html

build/esp-pmsa.kicad_pcb: esp-pmsa/esp-pmsa.kicad_pcb build
	kikit panelize extractboard -s 150 75 50 40 $< $@

build/esp-pmsa.sch: esp-pmsa/esp-pmsa.kicad_pcb build
	cp esp-pmsa/esp-pmsa.sch $@

build/esp-pmsa-panel.kicad_pcb: build/esp-pmsa.kicad_pcb build
	kikit panelize tightgrid \
		--gridsize 2 1 --space 3 --panelsize 60 90 --mousebites 0.5 1 0.25 \
		--vtabs 3 --htabs 3 --tabwidth 5 --tabheight 5 \
		--fiducials 10 2.5 1 2 --tooling 5 2.5 1.5 \
		--radius $(RADIUS) $< $@

build/esp-pmsa-panel.sch: esp-pmsa/esp-pmsa.kicad_pcb build
	cp esp-pmsa/esp-pmsa.sch $@

%-gerber: %.kicad_pcb
	kikit export gerber $< $@

%-gerber.zip: %-gerber
	zip -j $@ `find $<`

%-jlcpcb: %.sch %.kicad_pcb
	kikit fab jlcpcb --assembly --ignore $(JLCFAB_IGNORE) --schematic $^ $@

%-jlcpcb.zip: %-jlcpcb
	zip -j $@ `find $<`

web: build/web/index.html

build:
	mkdir -p build

build/web: build
	mkdir -p build/web

build/web/index.html: build/web $(BOARDSFILES)
	kikit present boardpage \
		-d README.md \
		--name "ESP32 CANBUS Controller Board" \
		-b "ESP32 CANBUS Controller Board" "Single board" build/esp-pmsa.kicad_pcb  \
		-b "ESP32 CANBUS Controller Board" "Panel of 2" build/esp-pmsa-panel.kicad_pcb  \
		-r "assets/esp-pmsa.png" \
		-r "assets/esp-pmsa-bottom.png" \
		-r "assets/esp-pmsa-top.png" \
		--repository "$(GITREPO)"\
		build/web

clean:
	rm -r build