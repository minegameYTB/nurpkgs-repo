{ lib, stdenvNoCC, substituteAll, writeScriptBin, makeWrapper, fastfetch, coreutils, gawk, bash, glfIcon ? "GLF" }:

let
  srcUrl = "https://framagit.org/gaming-linux-fr/glf-os/app-glf-os/glffetch/-/archive/main/glffetch-main.tar.gz";
in

assert lib.elem glfIcon [ "GLF" "GLFos" ] || throw "glfIcon must be either \"GLF\" or \"GLFos\" (got: ${glfIcon})";

stdenvNoCC.mkDerivation rec {
  pname = "GLFfetch";
  version = "1.2.alpha";

  src = builtins.fetchTarball {
    url = srcUrl;
    sha256 = "1wg79rs1s4l15q3p5y6v8f7avgil59rdbag65g8npjvmv352s3gj";
  };

  outputs = [ "out" "assets" ];
  outputsToInstall = outputs;

  buildInputs = [ fastfetch bash coreutils gawk ];
  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    substituteInPlace challenge.jsonc \
      --replace-warn "~/.config/fastfetch/GLFfetch/GLF.png" "$assets/share/${pname}/${glfIcon}.png" \
      --replace-warn "~/.config/fastfetch/GLFfetch" "$assets/share/${pname}" \
      --replace-warn "󰣇" "" \
      --replace-warn "/bin/bash" "${bash}/bin/bash"

    substituteInPlace scripts/challenge.sh \
      --replace-warn "/bin/bash" "${bash}/bin/bash" \
      --replace-warn "~/.config/fastfetch/GLFfetch" "$assets/share/${pname}"

    substituteInPlace scripts/completion.sh \
      --replace-warn "/bin/bash" "${bash}/bin/bash" \
      --replace-warn "~/.config/fastfetch/GLFfetch" "$assets/share/${pname}"

    substituteInPlace scripts/icon.sh \
      --replace-warn "/bin/bash" "${bash}/bin/bash" \
      --replace-warn '"$HOME"/.config/fastfetch/GLFfetch' "$assets/share/${pname}"

    substituteInPlace scripts/install_date.sh \
      --replace-warn "/bin/bash" "${bash}/bin/bash" \
      --replace-warn "~/.config/fastfetch/GLFfetch" "$assets/share/${pname}"

    sed -i '1a PATH="${coreutils}/bin:${gawk}/bin:"' scripts/vars.sh
    substituteInPlace scripts/vars.sh \
      --replace-warn "/bin/bash" "${bash}/bin/bash"
  '';

  installPhase = ''
    mkdir -p $out/bin $assets/share/${pname}
    mkdir -p $out/share/doc/${pname}

    cp -r . $assets/share/${pname}/

    mv $assets/share/${pname}/LICENSE $out/share/doc/${pname}/ 2>/dev/null || true
    mv $assets/share/${pname}/README.md $out/share/doc/${pname}/ 2>/dev/null || true

    ln -s $assets/share/${pname} $out/share/${pname}

    ${lib.optionalString (glfIcon == "GLFos") ''
      if [ -f ${./logo.png} ]; then
        ln -sf ${./logo.png} $assets/share/${pname}/${glfIcon}.png
        rm -f $assets/share/${pname}/GLF.png
      fi
    ''}

    chmod +x $assets/share/${pname}/scripts/*.sh
    makeWrapper ${fastfetch}/bin/fastfetch $out/bin/GLFfetch \
      --add-flags "--config $assets/share/${pname}/challenge.jsonc" \
      --prefix PATH : ${lib.makeBinPath [ coreutils gawk ]}
  '';

  meta = {
    description = "A customized neofetch config file built for the GLF Linux challenges";
    homepage = "https://framagit.org/gaming-linux-fr/glf-os";
    license = lib.licenses.mit;
    mainProgram = "GLFfetch";
  };
}