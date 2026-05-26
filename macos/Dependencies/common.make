TARGETFLAGS := $(TARGETFLAGS) -mmacosx-version-min=$(MINIMUM_REQUIRED)
DEPLOYMENT_TARGET_ENV := MACOSX_DEPLOYMENT_TARGET=$(MINIMUM_REQUIRED)
BUILD_PREFIX := ${PWD}/build-macosx-$(ARCH)
LIBDIR := $(BUILD_PREFIX)/lib
INCLUDEDIR := $(BUILD_PREFIX)/include
DOWNLOADS := ${PWD}/downloads/$(HOST)
DOWNLOAD_CACHE := ${PWD}/download-cache
NPROC := $(shell sysctl -n hw.ncpu 2>/dev/null || echo 4)
# Explicitly including freetype2 dir for now. macOS is having weird issues with ft2build.h
CFLAGS := -I$(INCLUDEDIR) -I$(INCLUDEDIR)/freetype2 $(TARGETFLAGS) $(DEFINES) -O3
LDFLAGS := -L$(LIBDIR)
CC      := clang -arch $(ARCH)
PKG_CONFIG_LIBDIR := $(BUILD_PREFIX)/lib/pkgconfig
GIT := git
CLONE := $(GIT) clone -q --depth 1 --single-branch
CURL := curl --http1.1 -fL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 20
GITHUB := https://github.com

THEORA_REV := 28fd5ec77f0ad0e07a371cef1047828116f6bd8a
SDL2_REV := d3ac4c3742a405e719071fc4f5a7ba8a125c76a1
SDL2_IMAGE_REV := d3c6d5963dbe438bcae0e2b6f3d7cfea23d02829
SDL_SOUND_REV := cfb2533eb3bac3700015cbd87cc623bea1467239
SDL2_TTF_REV := 0d5909ee2f1c95770d7fe76eb2fbd66ece26a5bf
FREETYPE_REV := 4d8db130ea4342317581bab65fc96365ce806b77
RUBY_REV := 4d85560cf65938d7883a323bf553acad1faf5eae

define DOWNLOAD_CACHED
	@mkdir -p $(DOWNLOAD_CACHE)
	@if [ -f "$(DOWNLOAD_CACHE)/$(1)" ]; then \
		echo "Using cached $(1)"; \
	else \
		echo "Downloading $(1)"; \
		$(CURL) -o "$(DOWNLOAD_CACHE)/$(1)" "$(2)"; \
	fi
endef

# need to set the build variable because Ruby is picky
ifeq "$(strip $(shell uname -m))" "arm64"
RBUILD := aarch64-apple-darwin
else
RBUILD := x86_64-apple-darwin
endif


CONFIGURE_ENV := \
	$(DEPLOYMENT_TARGET_ENV) \
	CMAKE_POLICY_VERSION_MINIMUM=3.10 \
	PKG_CONFIG_LIBDIR=$(PKG_CONFIG_LIBDIR) \
	CC="$(CC)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"

CONFIGURE_ARGS := \
	--prefix="$(BUILD_PREFIX)" \
	--host=$(HOST)

CMAKE_ARGS := \
	-DCMAKE_INSTALL_PREFIX="$(BUILD_PREFIX)" \
	-DCMAKE_PREFIX_PATH="$(BUILD_PREFIX)" \
	-DCMAKE_OSX_ARCHITECTURES=$(ARCH) \
	-DCMAKE_OSX_DEPLOYMENT_TARGET=$(MINIMUM_REQUIRED) \
	-DCMAKE_C_FLAGS="$(CFLAGS)" \
	-DCMAKE_BUILD_TYPE=Release


# Ruby won't think it's cross-compiling unless
# the BUILD variable is set now for whatever reason,
# but 
RUBY_CONFIGURE_ARGS := \
	--enable-install-static-library \
	--enable-shared \
	--with-out-ext=fiddle,gdbm,win32ole,win32 \
	--with-static-linked-ext \
	--disable-rubygems \
	--disable-install-doc \
	--build=$(RBUILD) \
	${EXTRA_RUBY_CONFIG_ARGS}

CONFIGURE := $(CONFIGURE_ENV) ./configure $(CONFIGURE_ARGS)
AUTOGEN   := $(CONFIGURE_ENV) ./autogen.sh $(CONFIGURE_ARGS)
CMAKE     := $(CONFIGURE_ENV) cmake .. $(CMAKE_ARGS)

default:

# Theora
libtheora: init_dirs libvorbis libogg $(LIBDIR)/libtheora.a

$(LIBDIR)/libtheora.a: $(LIBDIR)/libogg.a $(DOWNLOADS)/theora/Makefile
	cd $(DOWNLOADS)/theora; \
	make -j$(NPROC); make install

$(DOWNLOADS)/theora/Makefile: $(DOWNLOADS)/theora/configure
	cd $(DOWNLOADS)/theora; \
	$(CONFIGURE) --with-ogg=$(BUILD_PREFIX) --enable-shared=false --enable-static=true --disable-examples

$(DOWNLOADS)/theora/configure: $(DOWNLOADS)/theora/autogen.sh
	cd $(DOWNLOADS)/theora; \
	./autogen.sh

$(DOWNLOADS)/theora/autogen.sh:
	$(call DOWNLOAD_CACHED,theora-$(THEORA_REV).tar.gz,https://codeload.github.com/xiph/theora/tar.gz/$(THEORA_REV))
	mkdir -p $(DOWNLOADS)/theora
	tar -xzf $(DOWNLOAD_CACHE)/theora-$(THEORA_REV).tar.gz --strip-components=1 -C $(DOWNLOADS)/theora

# Vorbis
libvorbis: init_dirs libogg $(LIBDIR)/libvorbis.a

$(LIBDIR)/libvorbis.a: $(LIBDIR)/libogg.a $(DOWNLOADS)/vorbis/cmakebuild/Makefile
	cd $(DOWNLOADS)/vorbis/cmakebuild; \
	make -j$(NPROC); make install

$(DOWNLOADS)/vorbis/cmakebuild/Makefile: $(DOWNLOADS)/vorbis/CMakeLists.txt
	cd $(DOWNLOADS)/vorbis; \
	mkdir cmakebuild; cd cmakebuild; \
	$(CMAKE) -DBUILD_SHARED_LIBS=no

$(DOWNLOADS)/vorbis/CMakeLists.txt:
	$(CLONE) $(GITHUB)/xiph/vorbis -b v1.3.7 $(DOWNLOADS)/vorbis


# Ogg, dependency of Vorbis
libogg: init_dirs $(LIBDIR)/libogg.a

$(LIBDIR)/libogg.a: $(DOWNLOADS)/ogg/Makefile
	cd $(DOWNLOADS)/ogg; \
	make -j$(NPROC); make install

$(DOWNLOADS)/ogg/Makefile: $(DOWNLOADS)/ogg/configure
	cd $(DOWNLOADS)/ogg; \
	$(CONFIGURE) --enable-static=true --enable-shared=false

$(DOWNLOADS)/ogg/configure: $(DOWNLOADS)/ogg/autogen.sh
	cd $(DOWNLOADS)/ogg; ./autogen.sh

$(DOWNLOADS)/ogg/autogen.sh:
	$(CLONE) $(GITHUB)/xiph/ogg -b v1.3.6 $(DOWNLOADS)/ogg
	
# uchardet
uchardet: init_dirs $(LIBDIR)/libuchardet.a

$(LIBDIR)/libuchardet.a: $(DOWNLOADS)/uchardet/cmakebuild/Makefile
	cd $(DOWNLOADS)/uchardet/cmakebuild; \
	make -j$(NPROC); make install

$(DOWNLOADS)/uchardet/cmakebuild/Makefile: $(DOWNLOADS)/uchardet/CMakeLists.txt
	cd $(DOWNLOADS)/uchardet; \
	mkdir cmakebuild; cd cmakebuild; \
	$(CMAKE) -DBUILD_SHARED_LIBS=no

$(DOWNLOADS)/uchardet/CMakeLists.txt:
	$(CLONE) https://gitlab.freedesktop.org/uchardet/uchardet -b v0.0.8 $(DOWNLOADS)/uchardet


# Pixman
pixman: init_dirs libpng $(LIBDIR)/libpixman-1.a

$(LIBDIR)/libpixman-1.a: $(DOWNLOADS)/pixman/Makefile
	cd $(DOWNLOADS)/pixman
	make -C $(DOWNLOADS)/pixman -j$(NPROC)
	make -C $(DOWNLOADS)/pixman install

$(DOWNLOADS)/pixman/Makefile: $(DOWNLOADS)/pixman/autogen.sh
	cd $(DOWNLOADS)/pixman; \
	$(AUTOGEN) --enable-static=yes --enable-shared=no \
	--disable-arm-a64-neon

$(DOWNLOADS)/pixman/autogen.sh:
	$(CLONE) https://gitlab.freedesktop.org/pixman/pixman -b pixman-0.42.2 $(DOWNLOADS)/pixman


# PhysFS

physfs: init_dirs $(LIBDIR)/libphysfs.a

$(LIBDIR)/libphysfs.a: $(DOWNLOADS)/physfs/cmakebuild/Makefile
	cd $(DOWNLOADS)/physfs/cmakebuild; \
	make -j$(NPROC); make install

$(DOWNLOADS)/physfs/cmakebuild/Makefile: $(DOWNLOADS)/physfs/CMakeLists.txt
	cd $(DOWNLOADS)/physfs; \
	mkdir cmakebuild; cd cmakebuild; \
	$(CMAKE) -DPHYSFS_BUILD_STATIC=true -DPHYSFS_BUILD_SHARED=false

$(DOWNLOADS)/physfs/CMakeLists.txt:
	$(CLONE) $(GITHUB)/icculus/physfs -b release-3.2.0 $(DOWNLOADS)/physfs

# libpng
libpng: init_dirs $(LIBDIR)/libpng.a

$(LIBDIR)/libpng.a: $(DOWNLOADS)/libpng/Makefile
	cd $(DOWNLOADS)/libpng; \
	make -j$(NPROC); make install

$(DOWNLOADS)/libpng/Makefile: $(DOWNLOADS)/libpng/configure
	cd $(DOWNLOADS)/libpng; \
	$(CONFIGURE) \
	--enable-shared=no --enable-static=yes

$(DOWNLOADS)/libpng/configure:
	$(CLONE) $(GITHUB)/pnggroup/libpng -b v1.6.50 $(DOWNLOADS)/libpng

# SDL2
sdl2: init_dirs $(LIBDIR)/libSDL2.a

$(LIBDIR)/libSDL2.a: $(DOWNLOADS)/sdl2/cmakebuild/Makefile
	cd $(DOWNLOADS)/sdl2/cmakebuild; \
	make -j$(NPROC); make install

$(DOWNLOADS)/sdl2/cmakebuild/Makefile: $(DOWNLOADS)/sdl2/CMakeLists.txt
	cd $(DOWNLOADS)/sdl2; \
	mkdir cmakebuild; cd cmakebuild; \
	$(CMAKE) -DBUILD_SHARED_LIBS=no

$(DOWNLOADS)/sdl2/CMakeLists.txt:
	$(call DOWNLOAD_CACHED,sdl2-mkxp-z-$(SDL2_REV).tar.gz,https://codeload.github.com/mkxp-z/SDL/tar.gz/$(SDL2_REV))
	mkdir -p $(DOWNLOADS)/sdl2
	tar -xzf $(DOWNLOAD_CACHE)/sdl2-mkxp-z-$(SDL2_REV).tar.gz --strip-components=1 -C $(DOWNLOADS)/sdl2
	
# SDL_image
sdl2image: init_dirs sdl2 $(LIBDIR)/libSDL2_image.a

$(LIBDIR)/libSDL2_image.a: $(DOWNLOADS)/sdl2_image/cmakebuild/Makefile
	cd $(DOWNLOADS)/sdl2_image/cmakebuild; \
	make -j$(NPROC); make install

$(DOWNLOADS)/sdl2_image/cmakebuild/Makefile: $(DOWNLOADS)/sdl2_image/CMakeLists.txt
	cd $(DOWNLOADS)/sdl2_image; mkdir -p cmakebuild; cd cmakebuild; \
	$(CMAKE) \
	-DBUILD_SHARED_LIBS=no \
	-DSDL2IMAGE_JPG_SAVE=yes \
	-DSDL2IMAGE_PNG_SAVE=yes \
	-DSDL2IMAGE_PNG_SHARED=no \
	-DSDL2IMAGE_JPG_SHARED=no \
	-DSDL2IMAGE_AVIF=no \
	-DSDL2IMAGE_JXL=no \
	-DSDL2IMAGE_JXL_SHARED=no \
	-DSDL2IMAGE_BACKEND_IMAGEIO=no \
	-DSDL2IMAGE_VENDORED=yes
	

$(DOWNLOADS)/sdl2_image/CMakeLists.txt:
	$(call DOWNLOAD_CACHED,sdl2_image-mkxp-z-$(SDL2_IMAGE_REV).tar.gz,https://codeload.github.com/mkxp-z/SDL_image/tar.gz/$(SDL2_IMAGE_REV))
	mkdir -p $(DOWNLOADS)/sdl2_image
	tar -xzf $(DOWNLOAD_CACHE)/sdl2_image-mkxp-z-$(SDL2_IMAGE_REV).tar.gz --strip-components=1 -C $(DOWNLOADS)/sdl2_image
	cd $(DOWNLOADS)/sdl2_image; \
	set -e; \
	mkdir -p $(DOWNLOAD_CACHE); \
	for spec in \
		"external/jpeg https://codeload.github.com/libsdl-org/jpeg/tar.gz/v9e-SDL" \
		"external/libpng https://codeload.github.com/libsdl-org/libpng/tar.gz/v1.6.37-SDL" \
		"external/libwebp https://codeload.github.com/libsdl-org/libwebp/tar.gz/1.0.3-SDL" \
		"external/libtiff https://codeload.github.com/libsdl-org/libtiff/tar.gz/v4.2.0-SDL" \
		"external/zlib https://codeload.github.com/libsdl-org/zlib/tar.gz/v1.2.12-SDL"; do \
		set -- $$spec; \
		name=$$(basename $$1); \
		cache="$(DOWNLOAD_CACHE)/sdl2_image-$$name.tar.gz"; \
		mkdir -p $$1; \
		if [ -f "$$cache" ]; then \
			echo "Using cached sdl2_image-$$name.tar.gz"; \
		else \
			echo "Downloading sdl2_image-$$name.tar.gz"; \
			$(CURL) -o "$$cache" $$2; \
		fi; \
		tar -xzf "$$cache" --strip-components=1 -C $$1; \
	done


# SDL_sound
sdlsound: init_dirs sdl2 libogg libvorbis $(LIBDIR)/libSDL2_sound.a

$(LIBDIR)/libSDL2_sound.a: $(DOWNLOADS)/sdl_sound/cmakebuild/Makefile
	cd $(DOWNLOADS)/sdl_sound/cmakebuild; \
	make -j$(NPROC); make install

$(DOWNLOADS)/sdl_sound/cmakebuild/Makefile: $(DOWNLOADS)/sdl_sound/CMakeLists.txt
	cd $(DOWNLOADS)/sdl_sound; mkdir -p cmakebuild; cd cmakebuild; \
	$(CMAKE) \
	-DSDLSOUND_BUILD_SHARED=false \
	-DSDLSOUND_BUILD_TEST=false \
	-DSDLSOUND_DECODER_COREAUDIO=false

$(DOWNLOADS)/sdl_sound/CMakeLists.txt:
	$(call DOWNLOAD_CACHED,sdl_sound-$(SDL_SOUND_REV).tar.gz,https://codeload.github.com/mkxp-z/SDL_sound/tar.gz/$(SDL_SOUND_REV))
	mkdir -p $(DOWNLOADS)/sdl_sound
	tar -xzf $(DOWNLOAD_CACHE)/sdl_sound-$(SDL_SOUND_REV).tar.gz --strip-components=1 -C $(DOWNLOADS)/sdl_sound

	
# SDL2 (ttf)
sdl2ttf: init_dirs sdl2 freetype $(LIBDIR)/libSDL2_ttf.a

$(LIBDIR)/libSDL2_ttf.a: $(DOWNLOADS)/sdl2_ttf/Makefile
	cd $(DOWNLOADS)/sdl2_ttf; \
	make -j$(NPROC); make install

$(DOWNLOADS)/sdl2_ttf/Makefile: $(DOWNLOADS)/sdl2_ttf/configure
	cd $(DOWNLOADS)/sdl2_ttf; \
	$(CONFIGURE) --enable-static=true --enable-shared=false $(SDL2_TTF_FLAGS)

$(DOWNLOADS)/sdl2_ttf/configure: $(DOWNLOADS)/sdl2_ttf/autogen.sh
	cd $(DOWNLOADS)/sdl2_ttf; ./autogen.sh

$(DOWNLOADS)/sdl2_ttf/autogen.sh:
	$(call DOWNLOAD_CACHED,sdl2_ttf-mkxp-z-$(SDL2_TTF_REV).tar.gz,https://codeload.github.com/mkxp-z/SDL_ttf/tar.gz/$(SDL2_TTF_REV))
	mkdir -p $(DOWNLOADS)/sdl2_ttf
	tar -xzf $(DOWNLOAD_CACHE)/sdl2_ttf-mkxp-z-$(SDL2_TTF_REV).tar.gz --strip-components=1 -C $(DOWNLOADS)/sdl2_ttf

# Freetype (dependency of SDL2_ttf)
freetype: init_dirs $(LIBDIR)/libfreetype.a

$(LIBDIR)/libfreetype.a: $(DOWNLOADS)/freetype/Makefile
	cd $(DOWNLOADS)/freetype; \
	make -j$(NPROC); make install

$(DOWNLOADS)/freetype/Makefile: $(DOWNLOADS)/freetype/configure
	cd $(DOWNLOADS)/freetype; \
	$(CONFIGURE) --enable-static=true --enable-shared=false

$(DOWNLOADS)/freetype/configure: $(DOWNLOADS)/freetype/autogen.sh
	cd $(DOWNLOADS)/freetype; ./autogen.sh

$(DOWNLOADS)/freetype/autogen.sh:
	$(call DOWNLOAD_CACHED,freetype2-$(FREETYPE_REV).tar.gz,https://codeload.github.com/mkxp-z/freetype2/tar.gz/$(FREETYPE_REV))
	mkdir -p $(DOWNLOADS)/freetype
	tar -xzf $(DOWNLOAD_CACHE)/freetype2-$(FREETYPE_REV).tar.gz --strip-components=1 -C $(DOWNLOADS)/freetype

# OpenAL
openal: init_dirs libogg $(LIBDIR)/libopenal.a

$(LIBDIR)/libopenal.a: $(DOWNLOADS)/openal/cmakebuild/Makefile
	cd $(DOWNLOADS)/openal/cmakebuild; \
	make -j$(NPROC); make install

$(DOWNLOADS)/openal/cmakebuild/Makefile: $(DOWNLOADS)/openal/CMakeLists.txt
	cd $(DOWNLOADS)/openal; mkdir cmakebuild; cd cmakebuild; \
	$(CMAKE) -DLIBTYPE=STATIC -DALSOFT_EXAMPLES=no -DALSOFT_UTILS=no $(OPENAL_FLAGS)

$(DOWNLOADS)/openal/CMakeLists.txt:
	$(CLONE) $(GITHUB)/kcat/openal-soft -b 1.24.3 $(DOWNLOADS)/openal

# OpenSSL
openssl: init_dirs $(LIBDIR)/libssl.a
$(LIBDIR)/libssl.a: $(DOWNLOADS)/openssl/Makefile
	cd $(DOWNLOADS)/openssl; \
	$(CONFIGURE_ENV) make -j$(NPROC); make install_sw

$(DOWNLOADS)/openssl/Makefile: $(DOWNLOADS)/openssl/Configure
	cd $(DOWNLOADS)/openssl; \
	$(CONFIGURE_ENV) ./Configure $(OPENSSL_FLAGS) \
	no-shared \
	--prefix="$(BUILD_PREFIX)" \
	--openssldir="$(BUILD_PREFIX)"

$(DOWNLOADS)/openssl/Configure:
	$(call DOWNLOAD_CACHED,openssl-3.0.12.tar.gz,https://codeload.github.com/openssl/openssl/tar.gz/openssl-3.0.12)
	mkdir -p $(DOWNLOADS)/openssl
	tar -xzf $(DOWNLOAD_CACHE)/openssl-3.0.12.tar.gz --strip-components=1 -C $(DOWNLOADS)/openssl

# Standard ruby
ruby: init_dirs openssl $(LIBDIR)/libruby.3.1.dylib

$(LIBDIR)/libruby.3.1.dylib: $(DOWNLOADS)/ruby/Makefile
	cd $(DOWNLOADS)/ruby; \
	$(CONFIGURE_ENV) make -j$(NPROC); $(CONFIGURE_ENV) make install
	install_name_tool -id @rpath/libruby.3.1.dylib $(LIBDIR)/libruby.3.1.dylib

# -std=gnu99 is needed with GCC 15 and higher (which default to gnu23), for Ruby versions that aren't valid C23.
# Ruby versions that are valid C23 are 3.2.9+, 3.3.9+, 3.4.5+, and 3.5.0+.
$(DOWNLOADS)/ruby/Makefile: $(DOWNLOADS)/ruby/configure
	cd $(DOWNLOADS)/ruby; \
	export $(CONFIGURE_ENV); \
	export CFLAGS="-std=gnu99 -flto=full -DRUBY_FUNCTION_NAME_STRING=__func__ $$CFLAGS"; \
	export LDFLAGS="-flto=full $$LDFLAGS"; \
	./configure $(CONFIGURE_ARGS) $(RUBY_CONFIGURE_ARGS) $(RUBY_FLAGS)

$(DOWNLOADS)/ruby/configure: $(DOWNLOADS)/ruby/configure.ac
	cd $(DOWNLOADS)/ruby; autoreconf -i

$(DOWNLOADS)/ruby/configure.ac:
	$(call DOWNLOAD_CACHED,ruby-mkxp-z-3.1.3-$(RUBY_REV).tar.gz,https://codeload.github.com/mkxp-z/ruby/tar.gz/$(RUBY_REV))
	mkdir -p $(DOWNLOADS)/ruby
	tar -xzf $(DOWNLOAD_CACHE)/ruby-mkxp-z-3.1.3-$(RUBY_REV).tar.gz --strip-components=1 -C $(DOWNLOADS)/ruby
	sed -i '' '/: $${PRELOADENV=DYLD_INSERT_LIBRARIES}/g' $(DOWNLOADS)/ruby/configure.ac

# ====
init_dirs:
	@mkdir -p $(LIBDIR) $(INCLUDEDIR) $(DOWNLOAD_CACHE)

clean: clean-compiled

powerwash: clean-compiled clean-downloads

clean-cache:
	-rm -rf download-cache

clean-downloads:
	-rm -rf downloads/$(HOST)

clean-compiled:
	-rm -rf build-macosx-$(ARCH)

deps-core: libtheora libvorbis pixman libpng physfs uchardet sdl2 sdl2image sdlsound sdl2ttf openal openssl
everything: deps-core ruby
