{ lib, callPackage, pkgs }:

{
 ### Utilities
 sshrm = callPackage ./sshrm {}; 
 GLFfetch = callPackage ./GLFfetch {};
 GLFfetch-glfos = callPackage ./GLFfetch { glfIcon = "GLFos"; };

 ### dev set
 dev = {
   fhsEnv-shell = callPackage ./fhsEnv-shell {};
   fhsEnv-shell-clang = callPackage ./fhsEnv-shell { useClang = true; };
   fhsEnv-shell-krnl = callPackage ./fhsEnv-shell { kernel-tools = true; };
   fhsEnv-shell-buildroot = callPackage ./fhsEnv-shell { buildroot-tools = true; };
   fhsEnv-shell-all = callPackage ./fhsEnv-shell { kernel-tools = true; buildroot-tools = true; };
   fhsEnv-shell-all-clang = callPackage ./fhsEnv-shell { kernel-tools = true; buildroot-tools = true; };
 };

 ### Theme sets
 theme = {
   marble-shell-filled = callPackage ./marble-shell-filled {};
   
   ### marble-shell to marble-shell-filled with warning when this attribute is called
   marble-shell = let
      buildPackage = callPackage ./marble-shell-filled {};
    in 
      builtins.warn
      "[2024/03/12] marble-shell has been renamed to marble-shell-filled, consider migrating to this new name before deleting this attribute in 1 month. (nur.repos.minegameYTB.theme.marble-shell -> nur.repos.minegameYTB.theme.marble-shell-filled)"
      buildPackage;
 };

 # some-qt5-package = libsForQt5.callPackage ./some-qt5-package { };
 # ...
}
