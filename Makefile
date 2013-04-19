#
# Quake2 Makefile for Linux 2.0
#
# Nov '97 by Zoid <zoid@idsoftware.com>
#
# ELF only
#
#
# Modified by QuDos at http://qudos.quakedev.com
#

# Check OS type.
OSTYPE := $(shell uname -s)

# this nice line comes from the linux kernel makefile
#ARCH := $(shell uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc/ -e s/sparc64/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/alpha/axp/)

ARCH=i386


######################################
#OPTIONS
######################################

BUILD_DATADIR=NO                # Use DATADIR to read (data, renderers, etc.) and ~/.quake2 to write.
BUILD_GAME=YES                  # game$(ARCH).so
BUILD_KMQUAKE2=NO              # kmquake executable (uses OSS for cdrom and sound)
BUILD_KMQUAKE2_DEDICATED=NO	# build a dedicated kmquake2 server
BUILD_KMQUAKE2_SDL=YES           # kmquake2-sdl executable (uses SDL for cdrom and sound)
BUILD_LIBDIR=NO                 # Use LIBDIR to read data and renderers (independent from DATADIR).
ALSA_AUDIO=NO	                # Use Alsa for Linux audio

######################################

######################################

VERSION=0.1
MOUNT_DIR=.
BUILD_DEBUG_DIR=build_debug
BUILD_RELEASE_DIR=build_release
BINDIR=tfol

CC=gcc
BASE_CFLAGS= -Dstricmp=strcasecmp -D_stricmp=strcasecmp -D_strnicmp=strncasecmp -D__linux__ 
DEBUG_CFLAGS=$(BASE_CFLAGS) -ggdb -Wall -pipe
RELEASE_CFLAGS=$(BASE_CFLAGS) -O2 -ffast-math -funroll-loops -fomit-frame-pointer -fexpensive-optimizations

ifeq ($(ARCH),i386)
  RELEASE_CFLAGS+=-falign-loops=2 -falign-jumps=2 -falign-functions=2 -fno-strict-aliasing -m32
  DEBUG_CFLAGS+=-m32
endif

CLIENT_DIR=$(MOUNT_DIR)/client
UI_DIR=$(MOUNT_DIR)/ui
SERVER_DIR=$(MOUNT_DIR)/server
REF_GL_DIR=$(MOUNT_DIR)/renderer
COMMON_DIR=$(MOUNT_DIR)/qcommon
UNIX_DIR=$(MOUNT_DIR)/linux
GAME_DIR=$(MOUNT_DIR)/game
NULL_DIR=$(MOUNT_DIR)/null

ifeq ($(OSTYPE),FreeBSD)
  LDFLAGS=-lm -lz
endif
ifeq ($(OSTYPE),Linux)
  LDFLAGS=-lm -ldl -lz -lasound #-lefence
endif

#Ogg Vorbis support
LDFLAGS += \
	-lvorbisfile \
	-lvorbis \
	-logg 

#LOCALBASE?=/usr
LOCALBASE?=/usr/local
X11BASE?=/usr/X11R6
PREFIX?=$(LOCALBASE)

DATADIR?=$(LOCALBASE)/share/quake2
LIBDIR?=$(LOCALBASE)/lib/kmquake2

XCFLAGS=-I$(X11BASE)/include
GLCFLAGS=-I$(LOCALBASE)/include -I$(X11BASE)/include
GLXCFLAGS=-I$(LOCALBASE)/include -I$(X11BASE)/include -DOPENGL
GLXLDFLAGS=-L$(LOCALBASE)/lib -L$(X11BASE)/lib -lX11 -lXext -lXxf86dga -lXxf86vm -lGL -lGLU -lpng -ljpeg

SDL_CONFIG?=./sdl-config
SDLCFLAGS=$(shell $(SDL_CONFIG) --cflags)
SDLLDFLAGS=$(shell $(SDL_CONFIG) --libs)
SDLGLCFLAGS=$(SDLCFLAGS) -DOPENGL
SDLGLLDFLAGS=$(SDLLDFLAGS) -L

ifneq ($(ARCH),i386)
  BASE_CFLAGS+=-DC_ONLY
endif

ifeq ($(strip $(BUILD_DATADIR)),YES)
  BASE_CFLAGS+=-DDATADIR='\"$(DATADIR)\"'
endif

ifeq ($(strip $(BUILD_KMQUAKE2_SDL)),YES)
  BASE_CFLAGS+=-D_SDL_BIN
endif

ifeq ($(strip $(BUILD_LIBDIR)),YES)
  BASE_CFLAGS+=-DLIBDIR='\"$(LIBDIR)\"'
endif

SHLIBEXT=so

SHLIBCFLAGS=-fPIC
SHLIBLDFLAGS=-shared

DO_CC=$(CC) $(CFLAGS) -I$(LOCALBASE)/include -o $@ -c $<
DO_DED_CC=$(CC) $(CFLAGS) -DDEDICATED_ONLY -o $@ -c $<
DO_DED_DEBUG_CC=$(CC) $(DEBUG_CFLAGS) -DDEDICATED_ONLY -o $@ -c $<
DO_SHLIB_CC=$(CC) $(CFLAGS) $(SHLIBCFLAGS) -o $@ -c $<
DO_GL_SHLIB_CC=$(CC) $(CFLAGS) $(SHLIBCFLAGS) $(GLCFLAGS) -o $@ -c $<
DO_AS=$(CC) $(CFLAGS) -DELF -x assembler-with-cpp -o $@ -c $<
DO_SHLIB_AS=$(CC) $(CFLAGS) $(SHLIBCFLAGS) -DELF -x assembler-with-cpp -o $@ -c $<

#############################################################################
# SETUP AND BUILD
#############################################################################


.PHONY : targets debug release clean clean-debug clean-release clean2

ifeq ($(strip $(BUILD_KMQUAKE2)),YES)
  TARGETS+=$(BINDIR)/tfol
endif

ifeq ($(strip $(BUILD_KMQUAKE2_DEDICATED)),YES)
 TARGETS += $(BINDIR)/kmquake2_netserver
endif

ifeq ($(strip $(BUILD_KMQUAKE2_SDL)),YES)
  TARGETS+=$(BINDIR)/tfol-sdl
endif

ifeq ($(strip $(BUILD_GAME)),YES)
  TARGETS+=$(BINDIR)/baseq2/kmq2game$(ARCH).$(SHLIBEXT)
endif


all:
	@echo 
	@echo Set to YES or NO at the top of the file the possible binaries to build 
	@echo by the makefile.
	@echo By default, a 'make release' will build QuDos with maX support, a glx 
	@echo renderer the required game binary and some other features.
	@echo
	@echo Possible targets:
	@echo
	@echo ">> make release		build the binary for a release."
	@echo ">> make debug		build the binary for debuging mode."
	@echo ">> make install		will install to your quake2 home dir."
	@echo ">> make bz2		create a tar.bz2 compressed package."
	@echo ">> make clean		clean every '.o' object files."
	@echo ">> make distclean	clean objects, binaries and modified files."
	@echo 

bumf:
		mkdir -p $(BINDIR)
		cp README.TXT $(BINDIR)
		cp gnu.txt $(BINDIR)

kmq2config:	
		mkdir -p $(BINDIR)/baseq2
		cp config/kmq2config.cfg $(BINDIR)/baseq2

debug:

	@-mkdir -p $(BUILD_DEBUG_DIR) \
		$(BINDIR)/baseq2 \
		$(BUILD_DEBUG_DIR)/client \
		$(BUILD_DEBUG_DIR)/renderer \
		$(BUILD_DEBUG_DIR)/game \


	$(MAKE) targets BUILDDIR=$(BUILD_DEBUG_DIR) CFLAGS+="$(DEBUG_CFLAGS) -DKMQUAKE2_VERSION='\"$(VERSION) Debug\"'" kmq2config bumf


release:
	@-mkdir -p $(BUILD_RELEASE_DIR) \
		$(BINDIR)/baseq2 \
		$(BUILD_RELEASE_DIR)/client \
		$(BUILD_RELEASE_DIR)/renderer \
		$(BUILD_RELEASE_DIR)/game

	$(MAKE) targets BUILDDIR=$(BUILD_RELEASE_DIR) CFLAGS+="$(RELEASE_CFLAGS) -DKMQUAKE2_VERSION='\"$(VERSION)\"'" kmq2config bumf

targets: $(TARGETS)

#############################################################################
# CLIENT/SERVER
#############################################################################

QUAKE2_OBJS = \
	$(BUILDDIR)/client/cl_cin.o \
	$(BUILDDIR)/client/cl_cinematic.o \
	$(BUILDDIR)/client/cl_download.o \
	$(BUILDDIR)/client/cl_ents.o \
	$(BUILDDIR)/client/cl_event.o \
	$(BUILDDIR)/client/cl_fx.o \
	$(BUILDDIR)/client/cl_newfx.o \
	$(BUILDDIR)/client/cl_input.o \
	$(BUILDDIR)/client/cl_inv.o \
	$(BUILDDIR)/client/cl_lights.o \
	$(BUILDDIR)/client/cl_main.o \
	$(BUILDDIR)/client/cl_parse.o \
	$(BUILDDIR)/client/cl_pred.o \
	$(BUILDDIR)/client/cl_tempent.o \
	$(BUILDDIR)/client/cl_scrn.o \
	$(BUILDDIR)/client/cl_string.o \
	$(BUILDDIR)/client/cl_view.o \
	$(BUILDDIR)/client/cl_console.o \
	$(BUILDDIR)/client/cl_keys.o \
	$(BUILDDIR)/client/snd_dma.o \
	$(BUILDDIR)/client/snd_mem.o \
	$(BUILDDIR)/client/snd_mix.o \
	$(BUILDDIR)/client/snd_stream.o \
	$(BUILDDIR)/client/m_flash.o \
	$(BUILDDIR)/client/ui_backend.o \
	$(BUILDDIR)/client/ui_game.o \
	$(BUILDDIR)/client/ui_game_credits.o \
	$(BUILDDIR)/client/ui_game_saveload.o \
	$(BUILDDIR)/client/ui_main.o \
	$(BUILDDIR)/client/ui_mp_addressbook.o \
	$(BUILDDIR)/client/ui_mp_dmoptions.o \
	$(BUILDDIR)/client/ui_mp_download.o \
	$(BUILDDIR)/client/ui_mp_joinserver.o \
	$(BUILDDIR)/client/ui_mp_playersetup.o \
	$(BUILDDIR)/client/ui_mp_startserver.o \
	$(BUILDDIR)/client/ui_multiplayer.o \
	$(BUILDDIR)/client/ui_options.o \
	$(BUILDDIR)/client/ui_options_controls.o \
	$(BUILDDIR)/client/ui_options_interface.o \
	$(BUILDDIR)/client/ui_options_keys.o \
	$(BUILDDIR)/client/ui_options_sound.o \
	$(BUILDDIR)/client/ui_options_ingame.o \
	$(BUILDDIR)/client/ui_quit.o \
	$(BUILDDIR)/client/ui_subsystem.o \
	$(BUILDDIR)/client/ui_video.o \
	$(BUILDDIR)/client/ui_video_advanced.o \
	$(BUILDDIR)/client/cmd.o \
	$(BUILDDIR)/client/cmodel.o \
	$(BUILDDIR)/client/common.o \
	$(BUILDDIR)/client/crc.o \
	$(BUILDDIR)/client/cvar.o \
	$(BUILDDIR)/client/files.o \
	$(BUILDDIR)/client/md4.o \
	$(BUILDDIR)/client/net_chan.o \
	$(BUILDDIR)/client/wildcard.o \
	$(BUILDDIR)/client/sv_ccmds.o \
	$(BUILDDIR)/client/sv_ents.o \
	$(BUILDDIR)/client/sv_game.o \
	$(BUILDDIR)/client/sv_init.o \
	$(BUILDDIR)/client/sv_main.o \
	$(BUILDDIR)/client/sv_send.o \
	$(BUILDDIR)/client/sv_user.o \
	$(BUILDDIR)/client/sv_world.o \
	$(BUILDDIR)/client/q_shlinux.o \
	$(BUILDDIR)/client/vid_so.o \
	$(BUILDDIR)/client/sys_linux.o \
	$(BUILDDIR)/client/glob.o \
	\
	$(BUILDDIR)/client/net_udp.o \
	$(BUILDDIR)/client/q_shared.o \
	$(BUILDDIR)/client/pmove.o \
	$(BUILDDIR)/renderer/r_backend.o \
	$(BUILDDIR)/renderer/r_beam.o \
	$(BUILDDIR)/renderer/r_bloom.o \
	$(BUILDDIR)/renderer/r_cin.o \
	$(BUILDDIR)/renderer/r_draw.o \
	$(BUILDDIR)/renderer/r_entity.o \
	$(BUILDDIR)/renderer/r_fog.o \
	$(BUILDDIR)/renderer/r_fragment.o \
	$(BUILDDIR)/renderer/r_glstate.o \
	$(BUILDDIR)/renderer/r_image.o \
	$(BUILDDIR)/renderer/r_light.o \
	$(BUILDDIR)/renderer/r_main.o \
	$(BUILDDIR)/renderer/r_alias.o \
	$(BUILDDIR)/renderer/r_alias_md2.o \
	$(BUILDDIR)/renderer/r_alias_misc.o \
	$(BUILDDIR)/renderer/r_misc.o \
	$(BUILDDIR)/renderer/r_model.o \
	$(BUILDDIR)/renderer/r_particle.o \
	$(BUILDDIR)/renderer/r_sky.o \
	$(BUILDDIR)/renderer/r_sprite.o \
	$(BUILDDIR)/renderer/r_surf.o \
	$(BUILDDIR)/renderer/r_vlights.o \
	$(BUILDDIR)/renderer/gl_glx.o \
	$(BUILDDIR)/renderer/r_warp.o \
	\
	$(BUILDDIR)/renderer/qgl_linux.o \
	$(BUILDDIR)/client/unzip.o \
	$(BUILDDIR)/client/ioapi.o



QUAKE2_AS_OBJS =  $(BUILDDIR)/client/snd_mixa.o

ifeq ($(strip $(KMQUAKE2_SDL)), NO)
QUAKE2_LNX_OBJS = \
	$(BUILDDIR)/client/cd_linux.o \
	$(BUILDDIR)/client/snd_linux.o
endif  #KMQUAKE2_SDL

ifeq ($(strip $(ALSA_AUDIO)),YES)
QUAKE2_LNX_OBJS = \
	$(BUILDDIR)/client/cd_linux.o \
	$(BUILDDIR)/client/snd_alsa.o

QUAKE2_AS_OBJS = 
endif  #ALSA_AUDIO


QUAKE2_SDL_OBJS = \
	$(BUILDDIR)/client/snd_sdl.o \
	$(BUILDDIR)/client/cd_sdl.o

$(BINDIR)/tfol : $(QUAKE2_OBJS) $(QUAKE2_AS_OBJS) $(QUAKE2_LNX_OBJS)
	@echo
	@echo "==================== Linking $@ ===================="
	@echo
	$(CC) $(CFLAGS) -o $@ $(QUAKE2_OBJS) $(QUAKE2_AS_OBJS) $(QUAKE2_LNX_OBJS) $(GLXLDFLAGS) $(LDFLAGS) 

$(BINDIR)/tfol-sdl : $(QUAKE2_OBJS) $(QUAKE2_AS_OBJS) $(QUAKE2_SDL_OBJS) 
	@echo
	@echo "==================== Linking $@ ===================="
	@echo
	$(CC) $(CFLAGS) -o $@ $(QUAKE2_OBJS) $(QUAKE2_AS_OBJS) $(QUAKE2_SDL_OBJS) $(GLXLDFLAGS) $(LDFLAGS) $(SDLLDFLAGS)


$(BUILDDIR)/client/cl_cin.o :     	$(CLIENT_DIR)/cl_cin.c
	$(DO_CC)

$(BUILDDIR)/client/cl_cinematic.o :     $(CLIENT_DIR)/cl_cinematic.c
	$(DO_CC)

$(BUILDDIR)/client/cl_download.o :     	$(CLIENT_DIR)/cl_download.c
	$(DO_CC)

$(BUILDDIR)/client/cl_ents.o :    	$(CLIENT_DIR)/cl_ents.c
	$(DO_CC)

$(BUILDDIR)/client/cl_event.o :    	$(CLIENT_DIR)/cl_event.c
	$(DO_CC)

$(BUILDDIR)/client/cl_fx.o :      	$(CLIENT_DIR)/cl_fx.c
	$(DO_CC)

$(BUILDDIR)/client/cl_newfx.o :      	$(CLIENT_DIR)/cl_newfx.c
	$(DO_CC)

$(BUILDDIR)/client/cl_input.o :   	$(CLIENT_DIR)/cl_input.c
	$(DO_CC)

$(BUILDDIR)/client/cl_inv.o :     	$(CLIENT_DIR)/cl_inv.c
	$(DO_CC)

$(BUILDDIR)/client/cl_lights.o :    	$(CLIENT_DIR)/cl_lights.c
	$(DO_CC)

$(BUILDDIR)/client/cl_main.o :    	$(CLIENT_DIR)/cl_main.c
	$(DO_CC)

$(BUILDDIR)/client/cl_parse.o :   	$(CLIENT_DIR)/cl_parse.c
	$(DO_CC)

$(BUILDDIR)/client/cl_pred.o :    	$(CLIENT_DIR)/cl_pred.c
	$(DO_CC)

$(BUILDDIR)/client/cl_tempent.o :    	$(CLIENT_DIR)/cl_tempent.c
	$(DO_CC)

$(BUILDDIR)/client/cl_utils.o :    	$(CLIENT_DIR)/cl_utils.c
	$(DO_CC)

$(BUILDDIR)/client/cl_scrn.o :    	$(CLIENT_DIR)/cl_scrn.c
	$(DO_CC)

$(BUILDDIR)/client/cl_string.o :    	$(CLIENT_DIR)/cl_string.c
	$(DO_CC)

$(BUILDDIR)/client/cl_view.o :    	$(CLIENT_DIR)/cl_view.c
	$(DO_CC)

$(BUILDDIR)/client/cl_console.o :    	$(CLIENT_DIR)/cl_console.c
	$(DO_CC)

$(BUILDDIR)/client/cl_keys.o :       	$(CLIENT_DIR)/cl_keys.c
	$(DO_CC)

$(BUILDDIR)/client/snd_dma.o :    	$(CLIENT_DIR)/snd_dma.c
	$(DO_CC)

$(BUILDDIR)/client/snd_mem.o :    	$(CLIENT_DIR)/snd_mem.c
	$(DO_CC)

$(BUILDDIR)/client/snd_mix.o :    	$(CLIENT_DIR)/snd_mix.c
	$(DO_CC)

$(BUILDDIR)/client/snd_stream.o :    	$(CLIENT_DIR)/snd_stream.c
	$(DO_CC)

$(BUILDDIR)/client/m_flash.o :    	$(GAME_DIR)/m_flash.c
	$(DO_CC)

$(BUILDDIR)/client/ui_backend.o :    	$(UI_DIR)/ui_backend.c
	$(DO_CC)

$(BUILDDIR)/client/ui_game.o :    	$(UI_DIR)/ui_game.c
	$(DO_CC)

$(BUILDDIR)/client/ui_game_credits.o :    	$(UI_DIR)/ui_game_credits.c
	$(DO_CC)

$(BUILDDIR)/client/ui_game_saveload.o :    	$(UI_DIR)/ui_game_saveload.c
	$(DO_CC)

$(BUILDDIR)/client/ui_main.o :    	$(UI_DIR)/ui_main.c
	$(DO_CC)

$(BUILDDIR)/client/ui_mp_addressbook.o :    	$(UI_DIR)/ui_mp_addressbook.c
	$(DO_CC)

$(BUILDDIR)/client/ui_mp_dmoptions.o :    	$(UI_DIR)/ui_mp_dmoptions.c
	$(DO_CC)

$(BUILDDIR)/client/ui_mp_download.o :    	$(UI_DIR)/ui_mp_download.c
	$(DO_CC)

$(BUILDDIR)/client/ui_mp_joinserver.o :    	$(UI_DIR)/ui_mp_joinserver.c
	$(DO_CC)

$(BUILDDIR)/client/ui_mp_playersetup.o :    	$(UI_DIR)/ui_mp_playersetup.c
	$(DO_CC)

$(BUILDDIR)/client/ui_mp_startserver.o :    	$(UI_DIR)/ui_mp_startserver.c
	$(DO_CC)

$(BUILDDIR)/client/ui_multiplayer.o :    	$(UI_DIR)/ui_multiplayer.c
	$(DO_CC)

$(BUILDDIR)/client/ui_options.o :    $(UI_DIR)/ui_options.c
	$(DO_CC)	

$(BUILDDIR)/client/ui_local.o : 	$(UI_DIR)/ui_local.c
	$(DO_CC)

$(BUILDDIR)/client/ui_options_controls.o :    $(UI_DIR)/ui_options_controls.c
	$(DO_CC)

$(BUILDDIR)/client/ui_options_effects.o :    $(UI_DIR)/ui_options_effects.c
	$(DO_CC)

$(BUILDDIR)/client/ui_options_interface.o :    $(UI_DIR)/ui_options_interface.c
	$(DO_CC)

$(BUILDDIR)/client/ui_options_keys.o :    $(UI_DIR)/ui_options_keys.c
	$(DO_CC)

$(BUILDDIR)/client/ui_options_screen.o :    $(UI_DIR)/ui_options_screen.c
	$(DO_CC)

$(BUILDDIR)/client/ui_options_sound.o :    	$(UI_DIR)/ui_options_sound.c
	$(DO_CC)

$(BUILDDIR)/client/ui_options_ingame.o :    	$(UI_DIR)/ui_options_ingame.c
	$(DO_CC)

$(BUILDDIR)/client/ui_quit.o :    	$(UI_DIR)/ui_quit.c
	$(DO_CC)

$(BUILDDIR)/client/ui_subsystem.o :    	$(UI_DIR)/ui_subsystem.c
	$(DO_CC)

$(BUILDDIR)/client/ui_video.o :    	$(UI_DIR)/ui_video.c
	$(DO_CC)

$(BUILDDIR)/client/ui_video_advanced.o :    	$(UI_DIR)/ui_video_advanced.c
	$(DO_CC)

$(BUILDDIR)/client/cmd.o :        	$(COMMON_DIR)/cmd.c
	$(DO_CC)

$(BUILDDIR)/client/cmodel.o :     	$(COMMON_DIR)/cmodel.c
	$(DO_CC)

$(BUILDDIR)/client/common.o :     	$(COMMON_DIR)/common.c
	$(DO_CC)

$(BUILDDIR)/client/crc.o :        	$(COMMON_DIR)/crc.c
	$(DO_CC)

$(BUILDDIR)/client/cvar.o :       	$(COMMON_DIR)/cvar.c
	$(DO_CC)

$(BUILDDIR)/client/files.o :      	$(COMMON_DIR)/files.c
	$(DO_CC)

$(BUILDDIR)/client/md4.o :        	$(COMMON_DIR)/md4.c
	$(DO_CC)

$(BUILDDIR)/client/net_chan.o :   	$(COMMON_DIR)/net_chan.c
	$(DO_CC)

$(BUILDDIR)/client/wildcard.o :   	$(COMMON_DIR)/wildcard.c
	$(DO_CC)

$(BUILDDIR)/client/q_shared.o :   	$(GAME_DIR)/q_shared.c
	$(DO_CC)

$(BUILDDIR)/client/pmove.o :      	$(COMMON_DIR)/pmove.c
	$(DO_CC)

$(BUILDDIR)/client/sv_ccmds.o :   	$(SERVER_DIR)/sv_ccmds.c
	$(DO_CC)

$(BUILDDIR)/client/sv_ents.o :    	$(SERVER_DIR)/sv_ents.c
	$(DO_CC)

$(BUILDDIR)/client/sv_game.o :   	$(SERVER_DIR)/sv_game.c
	$(DO_CC)

$(BUILDDIR)/client/sv_init.o :    	$(SERVER_DIR)/sv_init.c
	$(DO_CC)

$(BUILDDIR)/client/sv_main.o :    	$(SERVER_DIR)/sv_main.c
	$(DO_CC)

$(BUILDDIR)/client/sv_send.o :    	$(SERVER_DIR)/sv_send.c
	$(DO_CC)

$(BUILDDIR)/client/sv_user.o :    	$(SERVER_DIR)/sv_user.c
	$(DO_CC)

$(BUILDDIR)/client/sv_world.o :   	$(SERVER_DIR)/sv_world.c
	$(DO_CC)

$(BUILDDIR)/client/cd_linux.o :   	$(UNIX_DIR)/cd_linux.c
	$(DO_CC)

$(BUILDDIR)/client/q_shlinux.o :  	$(UNIX_DIR)/q_shlinux.c
	$(DO_CC)

$(BUILDDIR)/client/vid_so.o :     	$(UNIX_DIR)/vid_so.c
	$(DO_CC)

$(BUILDDIR)/client/snd_alsa.o : 	$(UNIX_DIR)/snd_alsa.c
	$(DO_CC)

$(BUILDDIR)/client/snd_linux.o :  	$(UNIX_DIR)/snd_linux.c
	$(DO_CC)

$(BUILDDIR)/client/snd_mixa.o :   	$(UNIX_DIR)/snd_mixa.s
	$(DO_AS)

$(BUILDDIR)/client/sys_linux.o :  	$(UNIX_DIR)/sys_linux.c
	$(DO_CC)

$(BUILDDIR)/client/glob.o :       	$(UNIX_DIR)/glob.c
	$(DO_CC)

$(BUILDDIR)/client/in_linux.o :       	$(UNIX_DIR)/in_linux.c
	$(DO_CC)

$(BUILDDIR)/client/net_udp.o :    	$(UNIX_DIR)/net_udp.c
	$(DO_CC)

$(BUILDDIR)/client/cd_sdl.o :    	$(UNIX_DIR)/cd_sdl.c
	$(DO_CC) $(SDLCFLAGS)

$(BUILDDIR)/client/snd_sdl.o :    	$(UNIX_DIR)/snd_sdl.c
	$(DO_CC) $(SDLCFLAGS)

$(BUILDDIR)/client/ioapi.o :		$(UNIX_DIR)/zip/ioapi.c
	$(DO_CC)

$(BUILDDIR)/client/unzip.o : 		$(UNIX_DIR)/zip/unzip.c
	$(DO_CC)

$(BUILDDIR)/renderer/r_backend.o :        	$(REF_GL_DIR)/r_backend.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_beam.o :        	$(REF_GL_DIR)/r_beam.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_bloom.o :        	$(REF_GL_DIR)/r_bloom.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_cin.o :        	$(REF_GL_DIR)/r_cin.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_draw.o :        	$(REF_GL_DIR)/r_draw.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_entity.o :        	$(REF_GL_DIR)/r_entity.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_fog.o :        	$(REF_GL_DIR)/r_fog.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_fragment.o :       $(REF_GL_DIR)/r_fragment.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_glstate.o :       $(REF_GL_DIR)/r_glstate.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_image.o :       	$(REF_GL_DIR)/r_image.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_light.o :       	$(REF_GL_DIR)/r_light.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_main.o :       	$(REF_GL_DIR)/r_main.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_alias.o :       	$(REF_GL_DIR)/r_alias.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_alias_md2.o :        	$(REF_GL_DIR)/r_alias_md2.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_alias_misc.o :        	$(REF_GL_DIR)/r_alias_misc.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_arb_program.o :        	$(REF_GL_DIR)/r_arb_program.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_misc.o :       		$(REF_GL_DIR)/r_misc.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_model.o :       		$(REF_GL_DIR)/r_model.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_particle.o :       	$(REF_GL_DIR)/r_particle.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_sky.o :       		$(REF_GL_DIR)/r_sky.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_sprite.o :       	$(REF_GL_DIR)/r_sprite.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_surf.o :       		$(REF_GL_DIR)/r_surf.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_vlights.o :       	$(REF_GL_DIR)/r_vlights.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/r_warp.o :        	$(REF_GL_DIR)/r_warp.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/renderer/gl_glx.o :      	$(UNIX_DIR)/gl_glx.c
	$(DO_GL_SHLIB_CC) $(GLXCFLAGS)

$(BUILDDIR)/renderer/qgl_linux.o :      	$(UNIX_DIR)/qgl_linux.c
	$(DO_GL_SHLIB_CC)


#############################################################################
# DEDICATED SERVER
#############################################################################

Q2DED_OBJS = \
# 	\
# 	$(BUILDDIR)/ded/cmd.o \
# 	$(BUILDDIR)/ded/cmodel.o \
# 	$(BUILDDIR)/ded/common.o \
# 	$(BUILDDIR)/ded/crc.o \
# 	$(BUILDDIR)/ded/cvar.o \
# 	$(BUILDDIR)/ded/files.o \
# 	$(BUILDDIR)/ded/md4.o \
# 	$(BUILDDIR)/ded/net_chan.o \
# 	$(BUILDDIR)/ded/wildcard.o \
# 	$(BUILDDIR)/ded/unzip.o \
# 	$(BUILDDIR)/ded/ioapi.o\
# 	\
# 	$(BUILDDIR)/ded/sv_ccmds.o \
# 	$(BUILDDIR)/ded/sv_ents.o \
# 	$(BUILDDIR)/ded/sv_game.o \
# 	$(BUILDDIR)/ded/sv_init.o \
# 	$(BUILDDIR)/ded/sv_main.o \
# 	$(BUILDDIR)/ded/sv_send.o \
# 	$(BUILDDIR)/ded/sv_user.o \
# 	$(BUILDDIR)/ded/sv_world.o \
# 	\
# 	$(BUILDDIR)/ded/q_shlinux.o \
# 	$(BUILDDIR)/ded/sys_linux.o \
# 	$(BUILDDIR)/ded/glob.o \
# 	$(BUILDDIR)/ded/net_udp.o \
# 	\
# 	$(BUILDDIR)/ded/q_shared.o \
# 	$(BUILDDIR)/ded/pmove.o \
# 	\
# 	$(BUILDDIR)/ded/cl_null.o \
# 	$(BUILDDIR)/ded/cd_null.o


$(BINDIR)/kmquake2_netserver : $(Q2DED_OBJS)
	$(CC) $(CFLAGS) -o $@ $(Q2DED_OBJS) $(LDFLAGS)

$(BUILDDIR)/ded/cmd.o :        $(COMMON_DIR)/cmd.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/cmodel.o :     $(COMMON_DIR)/cmodel.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/common.o :     $(COMMON_DIR)/common.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/crc.o :        $(COMMON_DIR)/crc.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/cvar.o :       $(COMMON_DIR)/cvar.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/files.o :      $(COMMON_DIR)/files.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/md4.o :        $(COMMON_DIR)/md4.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/net_chan.o :   $(COMMON_DIR)/net_chan.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/wildcard.o :   $(COMMON_DIR)/wildcard.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/unzip.o :      $(UNIX_DIR)/zip/unzip.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/ioapi.o :      $(UNIX_DIR)/zip/ioapi.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/q_shared.o :   $(GAME_DIR)/q_shared.c
	$(DO_DED_DEBUG_CC)

$(BUILDDIR)/ded/pmove.o :      $(COMMON_DIR)/pmove.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sv_ccmds.o :   $(SERVER_DIR)/sv_ccmds.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sv_ents.o :    $(SERVER_DIR)/sv_ents.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sv_game.o :    $(SERVER_DIR)/sv_game.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sv_init.o :    $(SERVER_DIR)/sv_init.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sv_main.o :    $(SERVER_DIR)/sv_main.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sv_send.o :    $(SERVER_DIR)/sv_send.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sv_user.o :    $(SERVER_DIR)/sv_user.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sv_world.o :   $(SERVER_DIR)/sv_world.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/q_shlinux.o :   $(UNIX_DIR)/q_shlinux.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/sys_linux.o :   $(UNIX_DIR)/sys_linux.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/glob.o :       $(UNIX_DIR)/glob.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/net_udp.o :    $(UNIX_DIR)/net_udp.c
	$(DO_DED_CC)

$(BUILDDIR)/ded/cd_null.o :    $(NULL_DIR)/cd_null.c    
	$(DO_DED_CC)

$(BUILDDIR)/ded/cl_null.o :    $(NULL_DIR)/cl_null.c    
	$(DO_DED_CC)


#############################################################################
# GAME
#############################################################################

GAME_OBJS = \
	$(BUILDDIR)/game/acebot_ai.o \
	$(BUILDDIR)/game/acebot_cmds.o \
	$(BUILDDIR)/game/acebot_compress.o \
	$(BUILDDIR)/game/acebot_items.o \
	$(BUILDDIR)/game/acebot_movement.o \
	$(BUILDDIR)/game/acebot_nodes.o \
	$(BUILDDIR)/game/acebot_spawn.o \
	$(BUILDDIR)/game/g_ai.o \
	$(BUILDDIR)/game/g_camera.o \
	$(BUILDDIR)/game/g_chase.o \
	$(BUILDDIR)/game/g_cmds.o \
	$(BUILDDIR)/game/g_combat.o \
	$(BUILDDIR)/game/g_crane.o \
	$(BUILDDIR)/game/g_ctf.o \
	$(BUILDDIR)/game/g_fog.o \
	$(BUILDDIR)/game/g_func.o \
	$(BUILDDIR)/game/g_items.o \
	$(BUILDDIR)/game/g_jetpack.o \
	$(BUILDDIR)/game/g_lights.o \
	$(BUILDDIR)/game/g_lock.o \
	$(BUILDDIR)/game/g_main.o \
	$(BUILDDIR)/game/g_misc.o \
	$(BUILDDIR)/game/g_model.o \
	$(BUILDDIR)/game/g_monster.o \
	$(BUILDDIR)/game/g_moreai.o \
	$(BUILDDIR)/game/g_mtrain.o \
	$(BUILDDIR)/game/g_patchplayermodels.o \
	$(BUILDDIR)/game/g_pendulum.o \
	$(BUILDDIR)/game/g_phys.o \
	$(BUILDDIR)/game/g_reflect.o \
	$(BUILDDIR)/game/g_save.o \
	$(BUILDDIR)/game/g_spawn.o \
	$(BUILDDIR)/game/g_svcmds.o \
	$(BUILDDIR)/game/g_target.o \
	$(BUILDDIR)/game/g_thing.o \
	$(BUILDDIR)/game/g_tracktrain.o \
	$(BUILDDIR)/game/g_trigger.o \
	$(BUILDDIR)/game/g_turret.o \
	$(BUILDDIR)/game/g_utils.o \
	$(BUILDDIR)/game/g_vehicle.o \
	$(BUILDDIR)/game/g_weapon.o \
	$(BUILDDIR)/game/km_cvar.o \
	$(BUILDDIR)/game/m_actor.o \
	$(BUILDDIR)/game/m_actor_weap.o \
	$(BUILDDIR)/game/m_berserk.o \
	$(BUILDDIR)/game/m_boss2.o \
	$(BUILDDIR)/game/m_boss3.o \
	$(BUILDDIR)/game/m_boss31.o \
	$(BUILDDIR)/game/m_boss32.o \
	$(BUILDDIR)/game/m_brain.o \
	$(BUILDDIR)/game/m_chick.o \
	$(BUILDDIR)/game/m_flash.o \
	$(BUILDDIR)/game/m_flipper.o \
	$(BUILDDIR)/game/m_float.o \
	$(BUILDDIR)/game/m_flyer.o \
	$(BUILDDIR)/game/m_gladiator.o \
	$(BUILDDIR)/game/m_gunner.o \
	$(BUILDDIR)/game/m_hover.o \
	$(BUILDDIR)/game/m_infantry.o \
	$(BUILDDIR)/game/m_insane.o \
	$(BUILDDIR)/game/m_medic.o \
	$(BUILDDIR)/game/m_move.o \
	$(BUILDDIR)/game/m_mutant.o \
	$(BUILDDIR)/game/m_parasite.o \
	$(BUILDDIR)/game/m_soldier.o \
	$(BUILDDIR)/game/m_supertank.o \
	$(BUILDDIR)/game/m_tank.o \
	$(BUILDDIR)/game/p_chase.o \
	$(BUILDDIR)/game/p_client.o \
	$(BUILDDIR)/game/p_hud.o \
	$(BUILDDIR)/game/p_menu.o \
	$(BUILDDIR)/game/p_text.o \
	$(BUILDDIR)/game/p_trail.o \
	$(BUILDDIR)/game/p_view.o \
	$(BUILDDIR)/game/p_weapon.o \
	$(BUILDDIR)/game/q_shared.o \
	\
	$(BUILDDIR)/g_abel_camshoot.o \
	$(BUILDDIR)/g_abel_civspawner.o \
	$(BUILDDIR)/g_abel_dancespawner.o \
	$(BUILDDIR)/g_abel_floatspawner.o \
	$(BUILDDIR)/g_abel_gunarm.o \
	$(BUILDDIR)/g_abel_items.o \
	$(BUILDDIR)/g_abel_look.o \
	$(BUILDDIR)/g_abel_monster.o \
	$(BUILDDIR)/g_abel_script.o \
	$(BUILDDIR)/g_abel_target.o


$(BINDIR)/baseq2/kmq2game$(ARCH).$(SHLIBEXT) : $(GAME_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(GAME_OBJS) -lGL

$(BUILDDIR)/game/acebot_ai.o :          $(GAME_DIR)/acesrc/acebot_ai.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/acebot_cmds.o :        $(GAME_DIR)/acesrc/acebot_cmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/acebot_compress.o :    $(GAME_DIR)/acesrc/acebot_compress.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/acebot_items.o :       $(GAME_DIR)/acesrc/acebot_items.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/acebot_movement.o :    $(GAME_DIR)/acesrc/acebot_movement.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/acebot_nodes.o :       $(GAME_DIR)/acesrc/acebot_nodes.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/acebot_spawn.o :       $(GAME_DIR)/acesrc/acebot_spawn.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_ai.o :         	$(GAME_DIR)/g_ai.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_camera.o :      	$(GAME_DIR)/g_camera.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_chase.o :      	$(GAME_DIR)/g_chase.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_cmds.o :       	$(GAME_DIR)/g_cmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_combat.o :     	$(GAME_DIR)/g_combat.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_crane.o :      	$(GAME_DIR)/g_crane.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_ctf.o :      	$(GAME_DIR)/g_ctf.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_fog.o :      	$(GAME_DIR)/g_fog.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_func.o :       	$(GAME_DIR)/g_func.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_items.o :      	$(GAME_DIR)/g_items.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_jetpack.o :      	$(GAME_DIR)/g_jetpack.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_lights.o :      	$(GAME_DIR)/g_lights.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_lock.o :      	$(GAME_DIR)/g_lock.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_main.o :       	$(GAME_DIR)/g_main.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_misc.o :       	$(GAME_DIR)/g_misc.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_model.o :      	$(GAME_DIR)/g_model.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_monster.o :    	$(GAME_DIR)/g_monster.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_moreai.o :      	$(GAME_DIR)/g_moreai.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_mtrain.o :      	$(GAME_DIR)/g_mtrain.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_patchplayermodels.o : $(GAME_DIR)/g_patchplayermodels.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_pendulum.o :      	$(GAME_DIR)/g_pendulum.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_phys.o :       	$(GAME_DIR)/g_phys.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_reflect.o :       	$(GAME_DIR)/g_reflect.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_save.o :       	$(GAME_DIR)/g_save.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_spawn.o :      	$(GAME_DIR)/g_spawn.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_svcmds.o :     	$(GAME_DIR)/g_svcmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_target.o :     	$(GAME_DIR)/g_target.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_thing.o :      	$(GAME_DIR)/g_thing.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_tracktrain.o :      	$(GAME_DIR)/g_tracktrain.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_trigger.o :    	$(GAME_DIR)/g_trigger.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_turret.o :     	$(GAME_DIR)/g_turret.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_utils.o :      	$(GAME_DIR)/g_utils.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_vehicle.o :      	$(GAME_DIR)/g_vehicle.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_weapon.o :     	$(GAME_DIR)/g_weapon.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/km_cvar.o :      	$(GAME_DIR)/km_cvar.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_actor.o :      	$(GAME_DIR)/m_actor.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_actor_weap.o :      	$(GAME_DIR)/m_actor_weap.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_berserk.o :    	$(GAME_DIR)/m_berserk.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_boss2.o :      	$(GAME_DIR)/m_boss2.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_boss3.o :      	$(GAME_DIR)/m_boss3.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_boss31.o :     	$(GAME_DIR)/m_boss31.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_boss32.o :     	$(GAME_DIR)/m_boss32.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_brain.o :      	$(GAME_DIR)/m_brain.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_chick.o :      	$(GAME_DIR)/m_chick.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_flash.o :      	$(GAME_DIR)/m_flash.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_flipper.o :    	$(GAME_DIR)/m_flipper.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_float.o :      	$(GAME_DIR)/m_float.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_flyer.o :      	$(GAME_DIR)/m_flyer.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_gladiator.o :  	$(GAME_DIR)/m_gladiator.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_gunner.o :     	$(GAME_DIR)/m_gunner.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_hover.o :      	$(GAME_DIR)/m_hover.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_infantry.o :   	$(GAME_DIR)/m_infantry.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_insane.o :     	$(GAME_DIR)/m_insane.c
	$(DO_SHLIB_CC)	

$(BUILDDIR)/game/m_medic.o :      	$(GAME_DIR)/m_medic.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_move.o :       	$(GAME_DIR)/m_move.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_mutant.o :     	$(GAME_DIR)/m_mutant.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_parasite.o :   	$(GAME_DIR)/m_parasite.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_soldier.o :    	$(GAME_DIR)/m_soldier.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_supertank.o :  	$(GAME_DIR)/m_supertank.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_tank.o :       	$(GAME_DIR)/m_tank.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_chase.o :      	$(GAME_DIR)/p_chase.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_client.o :     	$(GAME_DIR)/p_client.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_hud.o :        	$(GAME_DIR)/p_hud.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_menu.o :      	$(GAME_DIR)/p_menu.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_text.o :      	$(GAME_DIR)/p_text.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_trail.o :      	$(GAME_DIR)/p_trail.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_view.o :       	$(GAME_DIR)/p_view.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_weapon.o :     	$(GAME_DIR)/p_weapon.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/q_shared.o :     	$(GAME_DIR)/q_shared.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_camshoot.o :		$(GAME_DIR)/g_abel_camshoot.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_civspawner.o :	$(GAME_DIR)/g_abel_civspawner.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_dancespawner.o :	$(GAME_DIR)/g_abel_dancespawner.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_floatspawner.o :	$(GAME_DIR)/g_abel_floatspawner.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_gunarm.o :	$(GAME_DIR)/g_abel_gunarm.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_items.o :	$(GAME_DIR)/g_abel_items.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_look.o :	$(GAME_DIR)/g_abel_look.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_monster.o :	$(GAME_DIR)/g_abel_monster.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_script.o :	$(GAME_DIR)/g_abel_script.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/g_abel_target.o :	$(GAME_DIR)/g_abel_target.c
	$(DO_SHLIB_CC)



#############################################################################
# MISC
#############################################################################

clean:
	@echo cleaning objects
	@rm -rf \
	$(BUILD_DEBUG_DIR) \
	$(BUILD_RELEASE_DIR)
	@echo .
	@echo .... Done

clean-bin:
	@echo cleaning binaries
	@-rm -rf $(BINDIR)
	@echo .
	@echo .... Done

distclean:
	@echo cleaning objects and binaries
	@-rm -rf $(BUILD_DEBUG_DIR) $(BUILD_RELEASE_DIR) $(BINDIR)
	@-rm -f `find . \( -not -type d \) -and \
		\( -name '*~' \) -type f -print`
	@echo .
	@echo .... Done

tar:
	@echo Creating tar file ...
	@tar cvf tfol-$(VERSION).tar $(BINDIR)
	@echo ... Done

gz:
	@echo Creating gzip compressed file ...
	@tar czvf tfol-$(VERSION).tar.gz $(BINDIR)
	@echo ... Done
bz2:
	@echo Creating bzip2 compressed file ...
	@tar cjvf tfol-$(VERSION).tar.bz2 $(BINDIR)
	@echo .... Done

install:
	@echo Copying files to your home dir ...
	@cp -r $(BINDIR) ~/
	@echo ... Done
