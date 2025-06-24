{ lib, callPackage, pkgs }:

{
 ### Utilities
 sshrm = callPackage ./tools/sshrm {}; 
 GLFfetch = callPackage ./misc/GLFfetch {};
 GLFfetch-glfos = callPackage ./misc/GLFfetch { glfIcon = "GLFos"; };

 ### Editor set
 editor = {
   msedit-bin = callPackage ./editor/msedit-bin {};
   msedit = callPackage ./editor/msedit-rs {};
 };

 ### dev set
 dev = {
   ### Without option (with clang variant)
   fhsEnv-shell = callPackage ./tools/fhsEnv-shell {};
   fhsEnv-shell-clang = callPackage ./tools/fhsEnv-shell { useClang = true; };

   ### With kernel-tools
   fhsEnv-shell-krnl = callPackage ./tools/fhsEnv-shell { kernel-tools = true; };
   
   ### With buildroot-tools
   fhsEnv-shell-buildroot = callPackage ./tools/fhsEnv-shell { buildroot-tools = true; };
   
   ### With debian-tools
   fhsEnv-shell-deb-tools = callPackage ./tools/fhsEnv-shell { debian-tools = true; };
   fhsEnv-shell-deb-tools-clang = callPackage ./toolsfhsEnv-shell { debian-tools = true; useClang = true; };
   fhsEnv-shell-deb-tools-krnl = callPackage ./tools/fhsEnv-shell { debian-tools = true; kernel-tools = true; };
   
   ### With redhat-tools
   fhsEnv-shell-rh-tools = callPackage ./tools/fhsEnv-shell { redhat-tools = true; };
   fhsEnv-shell-rh-tools-clang = callPackage ./tools/fhsEnv-shell { redhat-tools = true; useClang = true; };
   fhsEnv-shell-rh-tools-krnl = callPackage ./tools/fhsEnv-shell { redhat-tools = true; kernel-tools = true; };
   
   ### All configuration (With or without clang)
   fhsEnv-shell-all = callPackage ./tools/fhsEnv-shell { kernel-tools = true; buildroot-tools = true; };
   fhsEnv-shell-all-specific = callPackage ./tools/fhsEnv-shell { redhat-tools = true; debian-tools = true; kernel-tools = true; buildroot-tools = true; };
   fhsEnv-shell-all-specific-nokrnl = callPackage ./tools/fhsEnv-shell { redhat-tools = true; debian-tools = true; buildroot-tools = true; useClang = true;};
 };

 ### Theme sets
 theme = {
   marble-shell-filled = callPackage ./theme/marble-shell-filled {};
   
   ### marble-shell to marble-shell-filled with warning when this attribute is called
   #marble-shell = let
   #   buildPackage = callPackage ./theme/marble-shell-filled {};
   # in 
   #   builtins.warn
   #   "[2024/03/12] marble-shell has been renamed to marble-shell-filled, consider migrating to this new name before deleting this attribute in 1 month. (nur.repos.minegameYTB.theme.marble-shell -> nur.repos.minegameYTB.theme.marble-shell-filled)"
   #   buildPackage;
 };

 # some-qt5-package = libsForQt5.callPackage ./some-qt5-package { };
 # ...
}
