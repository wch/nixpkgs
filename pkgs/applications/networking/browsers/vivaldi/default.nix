{ stdenv, fetchurl, zlib, libX11, libXext, libSM, libICE
, libXfixes, libXt, libXi, libXcursor, libXScrnSaver, libXcomposite, libXdamage, libXtst, libXrandr
, alsaLib, dbus_libs, cups, libexif, ffmpeg, systemd
, freetype, fontconfig, libXft, libXrender, libxcb, expat, libXau, libXdmcp
, libuuid, xz
, gstreamer, gst_plugins_base, libxml2
, glib, gtk2, pango, gdk_pixbuf, cairo, atk, gnome3
, nss, nspr
, patchelf
}:

let
  version = "1.4";
  build = "589.29-1";
  fullVersion = "stable_${version}.${build}";

  info = if stdenv.is64bit then {
      arch = "amd64";
      sha256 = "14sb58qrqnqcpkzacwnwfln558p018zargppxq21p5ic8s92v1g6";
    } else {
      arch = "i386";
      sha256 = "0c4l9ji5xlxwzcjsrvxjkx53j76y777fj6hh7plfkkanlrfkryac";
    };

in stdenv.mkDerivation rec {
  product    = "vivaldi";
  name       = "${product}-${version}";

  src = fetchurl {
    inherit (info) sha256;
    url = "https://downloads.vivaldi.com/stable/${product}-${fullVersion}_${info.arch}.deb";
  };

  unpackPhase = ''
    ar vx ${src}
    tar -xvf data.tar.xz
  '';

  buildInputs =
    [ stdenv.cc.cc stdenv.cc.libc zlib libX11 libXt libXext libSM libICE
      libXi libXft libXcursor libXfixes libXScrnSaver libXcomposite libXdamage libXtst libXrandr
      atk alsaLib dbus_libs cups gtk2 gdk_pixbuf libexif ffmpeg systemd
      freetype fontconfig libXrender libuuid expat glib nss nspr
      gstreamer libxml2 gst_plugins_base pango cairo gnome3.gconf
      patchelf
    ];

  libPath = stdenv.lib.makeLibraryPath buildInputs
    + stdenv.lib.optionalString (stdenv.is64bit)
      (":" + stdenv.lib.makeSearchPathOutput "lib" "lib64" buildInputs);

  buildPhase = ''
    echo "Patching Vivaldi binaries"
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}" \
      opt/vivaldi/vivaldi-bin
    echo "Finished patching Vivaldi binaries"
  '';

  dontPatchELF = true;
  dontStrip    = true;

  installPhase = ''
    mkdir -p "$out"
    cp -r opt "$out"
    mkdir "$out/bin"
    ln -s "$out/opt/vivaldi/vivaldi" "$out/bin/vivaldi"
    mkdir -p "$out/share"
    cp -r usr/share/{applications,xfce4} "$out"/share
    substituteInPlace "$out"/share/applications/*.desktop \
      --replace /usr/bin/vivaldi-stable "$out"/bin/vivaldi
    local d
    for d in 16 22 24 32 48 64 128 256; do
      mkdir -p "$out"/share/icons/hicolor/''${d}x''${d}/apps
      ln -s \
        "$out"/opt/vivaldi/product_logo_''${d}.png \
        "$out"/share/icons/hicolor/''${d}x''${d}/apps/vivaldi.png
    done
  '';

  meta = with stdenv.lib; {
    description = "A Browser for our Friends, powerful and personal";
    homepage    = "https://vivaldi.com";
    license     = licenses.unfree;
    maintainers = with maintainers; [ otwieracz nequissimus ];
    platforms   = platforms.linux;
  };
}
